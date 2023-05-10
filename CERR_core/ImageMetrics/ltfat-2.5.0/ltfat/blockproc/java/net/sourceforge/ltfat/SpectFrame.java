/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package net.sourceforge.ltfat;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.MouseWheelEvent;
import java.awt.event.MouseWheelListener;
import java.awt.image.BufferedImage;
import java.awt.image.DataBuffer;
import java.awt.image.DataBufferByte;
import java.awt.image.IndexColorModel;
import java.awt.image.MultiPixelPackedSampleModel;
import java.awt.image.Raster;
import java.awt.image.SampleModel;
import java.awt.image.WritableRaster;
import java.lang.Override;
import java.lang.Runnable;
import java.lang.Throwable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JPopupMenu;
import javax.swing.JSlider;
import javax.swing.SwingUtilities;
import javax.swing.Timer;
import javax.swing.UIManager;
import javax.swing.UnsupportedLookAndFeelException;
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;
import net.sourceforge.ltfat.thirdparty.JRangeSlider;

/**
 *
 * @author zprusa
 */
public class SpectFrame {
    // Default image dimensions
    static final int defWidth = 800;
    static final int defHeight = 400;
    static final int heightRed = 4;
    // Actual image dimensions
    private int height = defHeight;
    private int width = defWidth;
    private JFrame jf = null;
    // Spectrogram has its own pannel
    SpectPanel spectPanel = null;
    private ExecutorService executor=Executors.newSingleThreadExecutor();
    // Default colormap length
    private int cmapLen = 256; 
    private byte[] colormap = null;
    IndexColorModel cm = null;
    private int sidx = 0;
    private int srunPos = 0;
    private int defSpeed = 2;
    private int spectStep = defSpeed*width/800;
    private String popupName = "LTFAT plot";
    private double climMax = 20;
    private double climMin = -70;
    private String climUnit = "dB";
    private final Object graphicsLock = new Object();

        /*
    Sanity check.
    Attempt to close the window if there was an exeption in the Matlab code
     */

    @Override
    public void finalize() throws Throwable{
        //System.out.println("Finalize called on SpectFrame");
        try{
            this.close();
        }
        catch(Throwable t){
            throw t;
        }
        finally {
            super.finalize();
        }

    }

    public SpectFrame(){
        this(defWidth,defHeight);
    }
   
    public SpectFrame(final int width, final int height) {
        
      colormap = new byte[cmapLen*3];  
      for(int yy=0;yy<cmapLen;yy++){
         colormap[3*yy] = (byte) yy;
         colormap[3*yy+1] = (byte) yy;
         colormap[3*yy+2] = (byte) yy;
      }
      cm = new IndexColorModel(8, cmapLen, colormap, 0, false);  
      
      runInEDT(new Runnable() {
            @Override
            public void run() {
              /*  try {
                    // Set System L&F
                    UIManager.setLookAndFeel(
                            UIManager.getSystemLookAndFeelClassName());
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
                //setColormap(cm);
                jf = initFrame(width,height);
                jf.pack();
            }
        });
    }

    public void requestFocus(){
        runInEDT(new Runnable() {
            @Override
            public void run() {
                if(jf != null){
                    jf.requestFocus();
                }
            }
        });
    }
    public void setLocation(final double x, final double y){
        runInEDT(new Runnable() {
            @Override
            public void run() {
                if(jf != null){
                    jf.setLocation((int)x,(int)y);
                }
            }
        });
    }

    public void show(){
        runInEDT(new Runnable() {
            @Override
            public void run() {
                if(jf!=null)
                    jf.setVisible(true);
            }
        });

    }


    /* Octave version */
    public void setColormap(double[] cmMat, double cMatLen, double cols){
    if (colormap==null ){
       colormap = new byte[cmapLen*3];   
    }
    int cmIdx = 0;
    float ratio = ((float)cMatLen)/((float)cmapLen);
    for(int yy=0;yy<cmapLen;yy++){
          for(int xx=0;xx<cols;xx++){
             double tmpVal = 255.0*cmMat[(int)(Math.floor(yy*ratio)+cMatLen*xx)];
             tmpVal = Math.min(tmpVal, 255.0);
             tmpVal = Math.max(tmpVal, 0.0);
             colormap[cmIdx++] = (byte) tmpVal;
          }
    }
        cm = new IndexColorModel(8, cmapLen, colormap, 0, false);
    }
    
    /* Matlab version */
    public void setColormap(double[][] cmMat){
    if (colormap==null ){
       colormap = new byte[cmapLen*3];   
    }
    int cmIdx = 0;
    int cMatLen = cmMat.length;
    float ratio = cMatLen/((float)cmapLen);
    for(int yy=0;yy<cmapLen;yy++){
          for(int xx=0;xx<cmMat[0].length;xx++){
             double tmpVal = 255.0*cmMat[(int)Math.floor(yy*ratio)][xx];
             tmpVal = Math.min(tmpVal, 255.0);
             tmpVal = Math.max(tmpVal, 0.0);
             colormap[cmIdx++] = (byte) tmpVal;
          }
    }
    
    cm = new IndexColorModel(8, cmapLen, colormap, 0, false);
    }
    
    public void close() {
        if (jf != null) {
            jf.setVisible(false);
            jf.dispose();
        }
        if( executor != null ){
           executor.shutdown();
        }
    }

    
    private JFrame initFrame(int width, int height){
        this.height = height;
        this.width = width;
        JFrame buildJF = new JFrame("LTFAT Plot Panel");
        buildJF.setLayout(new BorderLayout());
        spectPanel = new SpectPanel(width,height);
        
        buildJF.add(spectPanel);
        spectPanel.addWheelListener();
        
        
        JPopupMenu jpm = new JPopupMenu(popupName);
        
        JSlider speedSlider = new JSlider(JSlider.HORIZONTAL, 1, 10, defSpeed);
        speedSlider.addChangeListener(new ChangeListener() {

            @Override
            public void stateChanged(ChangeEvent e) {
                JSlider source = (JSlider)e.getSource();
                spectStep = source.getValue()*defWidth/800;
            }
        });
        
        JRangeSlider climSlider = new JRangeSlider((int)climMin, (int)climMax, (int)climMin,(int) climMax, JRangeSlider.HORIZONTAL);
        climSlider.addChangeListener(new ChangeListener() {

            @Override
            public void stateChanged(ChangeEvent e) {
                JRangeSlider source = (JRangeSlider)e.getSource();
                climMin = source.getLowValue();
                climMax = source.getHighValue();
            }
        });
        
         
        JLabel speedTxt = new JLabel("Speed:");
        JPanel speedPanel = new JPanel();
        speedPanel.add(speedTxt);
        speedPanel.add(speedSlider);
        speedSlider.setPreferredSize(new Dimension(100,speedSlider.getPreferredSize().height));
        jpm.add(speedPanel);
        
        JLabel climTxt = new JLabel("Limits:");
        JPanel climPanel = new JPanel();
        climPanel.add(climTxt);
        climPanel.add(climSlider);
        climSlider.setPreferredSize(new Dimension(100,climSlider.getPreferredSize().height));
        jpm.add(climPanel);
        
        
        spectPanel.addPopupMenu(jpm);
        return buildJF;
    }

    public int getHeight() {
      return this.height;
    }

    
    
    /*
     * Col is passed by value from Matlab
     */
      public void append(final double[] col, final double colHeight, final double colWidth) {


       runInPool(new Runnable() {
            @Override
            public void run() {
               if(spectPanel==null){
                  return;
	       }

	       Utils.pow(col);
               Utils.db(col);
               Float mindb = new Float(climMin);
               Float maxdb = new Float(climMax);
               Utils.clipToRange(col, mindb, maxdb);
               byte[] pixels = new byte[col.length];
               Utils.toByte(col, pixels, mindb, maxdb);

              //System.out.println(pixels);
               DataBuffer dbuf = new DataBufferByte(pixels, col.length, 0);
               SampleModel smod = new MultiPixelPackedSampleModel( DataBuffer.TYPE_BYTE,(int) colWidth,(int)colHeight, 8);
               WritableRaster raster = Raster.createWritableRaster(smod, dbuf, null);
               BufferedImage image = new BufferedImage(cm, raster, false, null);
           
             
               Graphics2D g2 = (Graphics2D) spectPanel.getGraphics2D();
               g2.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_NEAREST_NEIGHBOR);
               //g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
               g2.setRenderingHint(RenderingHints.KEY_COLOR_RENDERING, RenderingHints.VALUE_COLOR_RENDER_QUALITY);
               synchronized(graphicsLock)
               {
                  int startsrunPos = srunPos;
                  srunPos += spectStep;

                  if(srunPos>width){
                     g2.drawImage(image,startsrunPos,heightRed*height, width,0,0,0,(int)colWidth,(int)colHeight, null);
                     srunPos -= width;
                     startsrunPos = 0;
                  }
                  g2.drawImage(image,startsrunPos,heightRed*height, srunPos,0,0,0,(int)colWidth,(int)colHeight, null);
               }
              
               spectPanel.repaint();
            }
        });
    }
    
    
    public void append(final float[][] col) {

       final int colWidth = col[0].length;
       final int colHeight = col.length;

       runInPool(new Runnable() {
            @Override
            public void run() {
               Utils.pow(col);
               Utils.db(col);
               Float mindb = new Float(climMin);
               Float maxdb = new Float(climMax);
               Utils.clipToRange(col, mindb, maxdb);
               byte[] pixels = new byte[colWidth*colHeight];
               Utils.toByte(col, pixels, mindb, maxdb);

              //System.out.println(pixels);
               DataBuffer dbuf = new DataBufferByte(pixels, colWidth*colHeight, 0);
               SampleModel smod = new MultiPixelPackedSampleModel( DataBuffer.TYPE_BYTE, colWidth,colHeight, 8);
               WritableRaster raster = Raster.createWritableRaster(smod, dbuf, null);
               BufferedImage image = new BufferedImage(cm, raster, false, null);
           
             
               Graphics2D g2 = (Graphics2D) spectPanel.getGraphics2D();
               g2.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
               g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_OFF);
               g2.setRenderingHint(RenderingHints.KEY_COLOR_RENDERING, RenderingHints.VALUE_COLOR_RENDER_QUALITY);
               synchronized(graphicsLock)
               {
                  int startsrunPos = srunPos;
                  srunPos += spectStep;

                  if(srunPos>width){
                     g2.drawImage(image,startsrunPos,heightRed*height, width,0,0,0,colWidth,colHeight, null);
                     srunPos -= width;
                     startsrunPos = 0;
                  }
                  g2.drawImage(image,startsrunPos,heightRed*height, srunPos,0,0,0,colWidth,colHeight, null);
               }
               spectPanel.repaint();
            }
        });
    }
    
    public void append(double[][] col) {
      // System.out.println("Jessss"+col.length);
    }

     private void runInEDT(Runnable r){
        if (SwingUtilities.isEventDispatchThread()) {
            //   System.out.println("We are on on EDT. Strange....");
            try{
                r.run();
            }
            catch(Exception e){}
            catch(Throwable t){}
        } else {
            try{
                SwingUtilities.invokeLater(r);
            }
            catch(Exception e){}
            catch(Throwable t){}
        }
    }
     
     private void runInPool(Runnable r){
        if (SwingUtilities.isEventDispatchThread()) {
            System.out.println("Warning! We are on on EDT. Strange....");
        }
        try{
            executor.execute(r);
        }
        catch(Exception e){}
        catch(Throwable t){}
    } 
     
    private class SpectPanel extends JPanel{
        private BufferedImage spectbf = null;
        private float zoom = 1.0f;

        public void addWheelListener(){
        
            this.addMouseWheelListener(new MouseWheelListener() {

                @Override
                public void mouseWheelMoved(MouseWheelEvent e) {
                    if(e.getWheelRotation()>0){
                       zoom+=0.05;
                       zoom = Math.min(zoom,1.0f);
                    }
                    else{
                       zoom-=0.05;
                       zoom = Math.max(zoom,0.05f);
                    }
                        
                }
            });
        
        }

        public void addPopupMenu(JPopupMenu jpm){
            this.setComponentPopupMenu(jpm);
        }


        public SpectPanel(int width, int height) {
            Dimension dim = new Dimension(width, height);
            setSize(dim);
            setPreferredSize(dim);
            spectbf = new BufferedImage(width, heightRed*height, BufferedImage.TYPE_4BYTE_ABGR);

            Graphics2D bfGraphics = (Graphics2D) spectbf.getGraphics();
            bfGraphics.setColor(Color.LIGHT_GRAY);
            bfGraphics.fillRect(0, 0, width, heightRed*height);
            
        }
        
        public void setImage(BufferedImage bf){
          spectbf = bf;
        }
        
        protected void setZoom(float zoom)
        {
            this.zoom = zoom;
        }

        @Override
        public void paintComponent(Graphics g) {
            //super.paint(g);
            Dimension thisSize = this.getSize();
            Graphics2D g2d = (Graphics2D) g;
            g2d.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BILINEAR);
            g2d.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            g2d.setRenderingHint(RenderingHints.KEY_COLOR_RENDERING, RenderingHints.VALUE_COLOR_RENDER_SPEED);
            g2d.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_SPEED);
            
            if (spectbf != null) {
               //synchronized(bfLock){
               synchronized(graphicsLock)
               { 
                   
                  int winIdx = (int) (thisSize.width * srunPos/((float)spectbf.getWidth()));
                  int sbfH=(int)((1.0f-zoom)*spectbf.getHeight());
                  g2d.drawImage(spectbf,thisSize.width-winIdx,0,thisSize.width,thisSize.height,
                                        0,sbfH, srunPos,spectbf.getHeight(), null);
                  g2d.drawImage(spectbf,0,0,thisSize.width-winIdx,thisSize.height,
                                        srunPos,sbfH,spectbf.getWidth() , spectbf.getHeight(), null);
               }

            }
        }
        
        public Graphics2D getGraphics2D(){
           return (Graphics2D) spectbf.getGraphics();
        }
        
   

        
    
    }
    
    

}
