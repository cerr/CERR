/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package net.sourceforge.ltfat;

import java.awt.image.BufferedImage;
import java.awt.image.DataBufferFloat;

/**
 *
 * @author zprusa
 */
public class Utils {
    public static void abs(float[][] in)
    {
       int width = in[0].length;
       int height = in.length;
       for(int yy=0;yy<height;yy++){
          for(int xx=0;xx<width;xx++){
             in[yy][xx] = Math.abs(in[yy][xx]);
          }
       }
    }
    public static void pow(float[][] in)
    {
       int width = in[0].length;
       int height = in.length;
       for(int yy=0;yy<height;yy++){
          for(int xx=0;xx<width;xx++){
             in[yy][xx] = in[yy][xx]*in[yy][xx];
          }
       }
    }
    public static void db(float[][] in)
    {
       int width = in[0].length;
       int height = in.length;
       for(int yy=0;yy<height;yy++){
          for(int xx=0;xx<width;xx++){
             in[yy][xx] = (float) (20*Math.log10(in[yy][xx]+1e-10));
          }
       }
    }
    public static void abs(float[] in)
    {
       int height = in.length;
       for(int yy=0;yy<height;yy++){
             in[yy] = Math.abs(in[yy]);
       }
    }
    public static void pow(float[] in)
    {
       int height = in.length;
       for(int yy=0;yy<height;yy++){
             in[yy] = in[yy]*in[yy];
       }
    }
    public static void db(float[] in)
    {
       int height = in.length;
       for(int yy=0;yy<height;yy++){
             in[yy] = (float) (20*Math.log10(in[yy]+1e-10));
       }
    }
    public static void dynrange(float[][] in,int db, Float omin, Float omax)
    {
       omax = max(in);
       omin = omax - db;
       clipToRange(in, omin, omax);
    }
    public static float max(float[][] in)
    {
       float max = in[0][0];
       int width = in[0].length;
       int height = in.length;
       for(int yy=0;yy<height;yy++){
          for(int xx=0;xx<width;xx++){
             if(in[yy][xx]>max){
                max = in[yy][xx];
             }
          }
       }
       return max;
    }
    
    public static void clipToRange(float[][] in, float min, float max)
    {
       int width = in[0].length;
       int height = in.length;
       for(int yy=0;yy<height;yy++){
          for(int xx=0;xx<width;xx++){
             if(in[yy][xx]>max){
                in[yy][xx]=max;
             }
             if(in[yy][xx]<min){
                in[yy][xx]=min;
             }
          }
       }
    }
    
    public static void toByte(float[][] in, byte[] out, float min, float max )
    {
       int width = in[0].length;
       int height = in.length;
       for(int yy=0;yy<height;yy++){
          for(int xx=0;xx<width;xx++){
             out[yy*width+xx] = (byte) (255*(in[yy][xx]-min)/(max-min));
          }
       }
    }
    
    public static void clipToRange(float[] in, float min, float max)
    {
       int height = in.length;
       for(int yy=0;yy<height;yy++){
             if(in[yy]>max){
                in[yy]=max;
             }
             if(in[yy]<min){
                in[yy]=min;
             }
       }
    }
    
    public static void toByte(float[] in, byte[] out, float min, float max )
    {
       int height = in.length;
       for(int yy=0;yy<height;yy++){
             out[yy] = (byte) (255*(in[yy]-min)/(max-min));
       }
    }
    
    
    public static float inColormap(float[][] in, float min, float max, float[][] colormap, BufferedImage b)
    {
       int width = in[0].length;
       int height = in.length;
       int cvals = colormap.length;
       float[] bData = ((DataBufferFloat) b.getRaster().getDataBuffer()).getData();
       
       for(int yy=0;yy<height;yy++){
          for(int xx=0;xx<width;xx++){
            int cmapIdx = (int)(cvals*(in[yy][xx]-min)/max);
            bData[yy*width+xx] = colormap[cmapIdx][0];
            bData[yy*width+xx+1] = colormap[cmapIdx][1];
            bData[yy*width+xx+2] = colormap[cmapIdx][2];
          }
       }
       return max;
    }
    
    
    
    public static void abs(double[] in)
    {
       int height = in.length;
       for(int yy=0;yy<height;yy++){
             in[yy] = Math.abs(in[yy]);
       }
    }
    public static void pow(double[] in)
    {
       int height = in.length;
       for(int yy=0;yy<height;yy++){
             in[yy] = in[yy]*in[yy];
       }
    }
    public static void db(double[] in)
    {
       int height = in.length;
       for(int yy=0;yy<height;yy++){
             in[yy] = 20.0*Math.log10(in[yy]+1e-10);
       }
    }
    
    
    public static void clipToRange(double[] in, float min, float max)
    {
       int height = in.length;
       for(int yy=0;yy<height;yy++){
             if(in[yy]>max){
                in[yy]=max;
             }
             if(in[yy]<min){
                in[yy]=min;
             }
       }
    }
    
    public static void toByte(double[] in, byte[] out, float min, float max )
    {
       int height = in.length;
       for(int yy=0;yy<height;yy++){
             out[yy] = (byte) (255*(in[yy]-min)/(max-min));
       }
    }
}
