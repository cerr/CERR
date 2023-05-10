/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package net.sourceforge.ltfat;

import java.awt.*;
import javax.swing.*;
import java.awt.KeyEventDispatcher;
import java.awt.KeyboardFocusManager;
import java.util.List;
import java.awt.event.KeyEvent;
import java.lang.Override;
import java.util.*;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;
import java.lang.Throwable;

/**
 *
 * @author zprusa
 */
public class ContFrame
{
   volatile private boolean showLoadInd = false;
   private JFrame jf = null;
   private Map paramMap = null;
   private Map sliderParamMap = null;
   private Map paramComponentsMap = null;
   private Map sliderBoundsMap = null;
   private KeyboardFocusManager kfm = null;
   private KeyEventDispatcher ked = null;
   public double flag = 1;
   private ExecutorService executor = Executors.newSingleThreadExecutor();

   JLabel loadLabel;
   JProgressBar loadBar;
   JLabel loadTxt;

   // Components
   private int defXPad = 3;
   private int defYPad = 10;
   private int namePrefferedSize = 70;
   private int sliderPrefferedSize = 170;
   private int valuePrefferedSize = 30;

   /*
   Sanity check.
   Attempt to close the window if there was an exeption in the Matlab code
    */

   @Override
   public void finalize() throws Throwable
   {
      //System.out.println("Finalize called on ContFrame");
      try
      {
         this.close();
      }
      catch (Throwable t)
      {
         throw t;
      }
      finally
      {
         super.finalize();
      }

   }


   public void setVisibleParam(String param, boolean visible ) throws NoSuchFieldException
   {
      // Do nothing if paramSliderMap has not been initlialized yet
      if (paramComponentsMap == null)
         return;

      List<JComponent> s = (List<JComponent>) paramComponentsMap.get(param);
      if (s == null)
      {
         throw new NoSuchFieldException("Parameter " + param + " not found.");
      }

      for (JComponent c : s)
      {
         c.setVisible(visible);
      }

      //s.disable();
      //s.setVisible(false);
   }



   public double getParam(String key) throws NoSuchFieldException
   {
      if (paramMap == null)
         return 0;

      Double d = (Double) paramMap.get(key);
      if (d == null)
      {
         throw new NoSuchFieldException("Parameter " + key + " not found.");
      }
      return (Double)paramMap.get(key);
   }

   public double[] getParams(String... key) throws NoSuchFieldException
   {
      int keyLen = key.length;
      double[] out = new double[keyLen];
      for (int ii = 0; ii < keyLen; ii++)
      {
         try
         {
            out[ii] = getParam(key[ii]);
         }
         catch (NoSuchFieldException err)
         {
            throw(err);
         }
      }
      return out;
   }

   public double[] getParams()
   {
      int outLen = paramMap.size();
      if (outLen == 0)
      {
         throw new NullPointerException("Parameter map is empty");
      }
      Iterator it = paramMap.entrySet().iterator();
      double[] out = new double[outLen];
      int ii = 0;
      while (it.hasNext())
      {
         Map.Entry act = (Map.Entry) it.next();
         out[ii++] = (Double) act.getValue();
      }
      return out;
   }

   public void addControlElements(final List params)
   {
      // Ensure everything is done in the EDT
      runInEDT(new Runnable()
      {
         @Override
         public void run()
         {
            paramMap = new LinkedHashMap<String, Double>();
            sliderParamMap = new HashMap<JSlider, String>();
            paramComponentsMap = new HashMap<String, List<JComponent>>();
            sliderBoundsMap = new HashMap<JSlider, SliderBounds>();
            initFrameComponents(params);
            jf.pack();
            jf.validate();
            jf.setVisible(true);
         }
      });
   }

   public void close()
   {
      // This is uded to escape the main loop
      flag = 0;
      // We have to remove the Ctrl-C blocker
      if (kfm != null && ked != null)
      {
         kfm.removeKeyEventDispatcher(ked);
      }
      
      // Dispose the JFrame, this object lives on
      if (jf != null)
      {
         jf.setVisible(false);
         jf.dispose();
      }
   }

   private void onExit()
   {
      close();
   }


   private void runInEDT(Runnable r)
   {
      if (SwingUtilities.isEventDispatchThread())
      {
         //   System.out.println("We are on on EDT. Strange....");
         try
         {
            r.run();
         }
         catch (Exception e) {}
         catch (Throwable t) {}
      }
      else
      {
         try
         {
            SwingUtilities.invokeLater(r);
         }
         catch (Exception e) {}
         catch (Throwable t) {}
      }
   }

   private void runInPool(Runnable r)
   {
      if (SwingUtilities.isEventDispatchThread())
      {
         System.out.println("Warning! We are on on EDT. Strange....");
      }
      try
      {
         executor.execute(r);
      }
      catch (Exception e) {}
      catch (Throwable t) {}
   }

   public void updateBar(final double val)
   {
      runInPool( new Runnable()
      {
         public void run()
         {
            if (loadLabel == null || loadBar == null || loadTxt == null)
               return;

            if (!showLoadInd)
            {
               loadLabel.setVisible(true);
               loadBar.setVisible(true);
               loadTxt.setVisible(true);
               if(jf != null)
               {
                   jf.pack();
               }
            }
            loadBar.setValue((int)val);
            loadTxt.setText(String.format(" %d%%", ((int)val)));
            if ((int)val > 80)
            {
               loadTxt.setForeground(Color.red);
            }
            else
            {
               loadTxt.setForeground(Color.black);
            }

            showLoadInd = true;
            loadBar.repaint();
            loadTxt.repaint();
         }
      });

   }

   public ContFrame()
   {
      runInEDT( new Runnable()
      {
         @Override
         public void run()
         {
            /* try {
                 // Set System L&F
                 UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
             } catch (UnsupportedLookAndFeelException e) {
                 // handle exception
             } catch (ClassNotFoundException e) {
                 // handle exception
             } catch (InstantiationException e) {
                 // handle exception
             } catch (IllegalAccessException e) {
                 // handle exception
             }
            */
            jf = initFrame();
         }
      });

   }

   public void requestFocus()
   {
      runInEDT(new Runnable()
      {
         @Override
         public void run()
         {
            if (jf != null)
            {
               jf.requestFocus();
            }
         }
      });
   }
   public void setLocation(final double x, final double y)
   {
      runInEDT( new Runnable()
      {
         @Override
         public void run()
         {
            jf.setLocation((int)x, (int)y);
         }
      });
   }


   private JFrame initFrame()
   {
      final JFrame buildJF = new JFrame("LTFAT Control Panel");
      buildJF.setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
      buildJF.addWindowListener(new java.awt.event.WindowAdapter()
      {
         @Override
         public void windowClosing(java.awt.event.WindowEvent windowEvent)
         {
           close();
         }
      });

      // Add a global Ctrc-C keyboard shortcut listener
      kfm = KeyboardFocusManager.getCurrentKeyboardFocusManager();
      ked = new KeyEventDispatcher()
      {
         @Override
         public boolean dispatchKeyEvent(KeyEvent e)
         {
            if (e.isControlDown() && e.getKeyCode() == KeyEvent.VK_C &&
                  e.getID() == KeyEvent.KEY_PRESSED)
            {
               // The Ctrl-C is consumed here. It is not passed further.
               e.consume();
               close();
            }
            return false;
         }
      };
      kfm.addKeyEventDispatcher(ked);

      return buildJF;
   }

   private void initFrameComponents(List<List> params)
   {
      GridBagLayout gl =  new GridBagLayout();
      jf.setLayout(gl);
      GridBagConstraints labelConst = new GridBagConstraints();
      GridBagConstraints sliderConst = new GridBagConstraints();
      GridBagConstraints valConst = new GridBagConstraints();

      labelConst.gridx = 0;
      labelConst.gridy = 0;
      labelConst.fill = GridBagConstraints.VERTICAL;
      labelConst.ipadx = defXPad;
      labelConst.ipady = defYPad;
      labelConst.anchor = GridBagConstraints.CENTER;
      labelConst.weightx = 0.2;
      labelConst.weighty = 1.0 / params.size();

      sliderConst.gridx = 1;
      sliderConst.gridy = 0;
      sliderConst.fill = GridBagConstraints.HORIZONTAL;
      sliderConst.ipadx = defXPad;
      sliderConst.ipady = defYPad;
      sliderConst.anchor = GridBagConstraints.CENTER;
      sliderConst.weightx = 0.7;
      sliderConst.weighty = 1.0 / params.size();

      valConst.gridx = 2;
      valConst.gridy = 0;
      valConst.fill = GridBagConstraints.BOTH;
      valConst.ipadx = defXPad;
      valConst.ipady = defYPad;
      valConst.anchor = GridBagConstraints.LINE_START;
      valConst.weightx = 0.1;
      valConst.weighty = 1.0 / params.size();
      valConst.insets = new Insets(10, 0, 0, 0);

      for (List lEl : params)
      {
         String name = new String("noname");
         String label = new String("nolabel");
         Object labelObj = lEl.get(1);
         if (labelObj instanceof Character)
         {
            label = ((Character)labelObj).toString();
         }
         else if (labelObj instanceof String)
         {
            label = (String)labelObj;
         }
         Object nameObj = lEl.get(0);
         if (nameObj instanceof Character)
         {
            name = ((Character)nameObj).toString();
         }
         else if (nameObj instanceof String)
         {
            name = (String)nameObj;
         }

         Double minVal = (Double) lEl.get(2);
         Double maxVal = (Double)lEl.get(3);
         Double defaultVal = (Double)lEl.get(4);
         int noVal = ((Double)lEl.get(5)).intValue();
         int defValSlider = val2slider(defaultVal, minVal, maxVal, noVal);

         JLabel jname = new JLabel(label);
         JSlider jval = new JSlider(0, noVal - 1, defValSlider);
         final JLabel jvalTxt = new JLabel(String.format("%.3g    ",
                                           slider2val(jval.getValue(),
                                                 minVal, maxVal, noVal)));
         jvalTxt.setPreferredSize(new Dimension(50, 10));
         jval.addChangeListener(new ChangeListener()
         {
            @Override
            public void stateChanged(ChangeEvent e)
            {
               JSlider jslider = (JSlider) e.getSource();
               int sliIntVal = jslider.getValue();
               double sliMinVal = ((SliderBounds)sliderBoundsMap.get(jslider)).getMinVal();
               double sliMaxVal = ((SliderBounds)sliderBoundsMap.get(jslider)).getMaxVal();
               double sliVal = slider2val(sliIntVal, sliMinVal, sliMaxVal, jslider.getMaximum() + 1);

               final Dimension jvalTxtDim = jvalTxt.getPreferredSize();
               jvalTxt.setMinimumSize(jvalTxtDim);
               jvalTxt.setMaximumSize(jvalTxtDim);
               jvalTxt.setText(String.format("%.3g", sliVal));
               paramMap.put(sliderParamMap.get(jslider), sliVal );
            }
         });


         jf.add(jname, labelConst);
         labelConst.gridy += 1;
         jf.add(jval, sliderConst);
         sliderConst.gridy += 1;
         jf.add(jvalTxt, valConst);
         valConst.gridy += 1;


         paramMap.put(name, defaultVal);
         sliderParamMap.put(jval, name);
         ArrayList l = new ArrayList<JComponent>();
         l.add(jname);
         l.add(jval);
         l.add(jvalTxt);
         paramComponentsMap.put(name, l);
         sliderBoundsMap.put(jval, new SliderBounds(minVal, maxVal));
      }


      loadTxt = new JLabel("0%");
      loadTxt.setPreferredSize(new Dimension(50, 10));
      loadLabel = new JLabel("Load:");
      loadBar = new JProgressBar();

      jf.add(loadLabel, labelConst);
      jf.add(loadBar, sliderConst);
      jf.add(loadTxt, valConst);
      loadLabel.setVisible(false);
      loadBar.setVisible(false);
      loadTxt.setVisible(false);
   }

   private int val2slider(double val, double minVal, double maxVal, int noVal)
   {
      int retVal = (int)Math.round((val - minVal) / (maxVal - minVal) * (noVal - 1));
      return Math.min(Math.max(retVal, 0), noVal);
   }

   private double slider2val(int slider, double minVal, double maxVal, int noVal)
   {
      double retVal = ((double)slider) / (noVal - 1) * (maxVal - minVal) + minVal;
      return Math.min(Math.max(retVal, minVal), maxVal);
   }

   private class SliderBounds
   {
      private double minVal = 0.0;
      private double maxVal = 0.0;
      SliderBounds(double minVal, double maxVal)
      {
         this.minVal = minVal;
         this.maxVal = maxVal;
      }

      double getMaxVal()
      {
         return maxVal;
      }

      double getMinVal()
      {
         return minVal;
      }
   }
}
