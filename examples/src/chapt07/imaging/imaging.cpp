// Imaging.cpp
// OpenGL SuperBible
// Demonstrates Imaging Operations
// Program by Richard S. Wright Jr.

#include "../../shared/gltools.h"  // OpenGL toolkit

#include <math.h>

#include <stdio.h>

#include <stdlib.h>

//////////////////////////////////////////////////////////////////
// Module globals to save source image data
static GLbyte* pImage = NULL;
static GLint iWidth, iHeight, iComponents;
static GLenum eFormat;

// Global variable to store desired drawing mode
static GLint iRenderMode = 1;
static GLboolean bHistogram = GL_FALSE;

//////////////////////////////////////////////////////////////////
// This function does any needed initialization on the rendering
// context.
void SetupRC(void) {
  // Black background
  glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

  // Load the horse image
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  pImage = gltLoadTGA("horse.tga", &iWidth, &iHeight, &iComponents, &eFormat);
}

void ShutdownRC(void) {
  // Free the original image data
  free(pImage);
}

///////////////////////////////////////////////////////////////////////////////
// Reset flags as appropriate in response to menu selections
void ProcessMenu(int value) {
  // For historgram, do not change render mode, just set
  // histogram flag to true
  if (value == 6)  // Histogram
  {
    bHistogram = GL_TRUE;
    glutPostRedisplay();
    return;
  }

  if (value == 0)
    // Save image
    gltWriteTGA("ScreenShot.tga");
  else
    // Change render mode index to match menu entry index
    iRenderMode = value;

  // Trigger Redraw
  glutPostRedisplay();
}

///////////////////////////////////////////////////////////////////////
// The imaging operations, done on the CPU. The book used the GL_ARB_imaging
// subset (glConvolutionFilter2D, glColorTable, the color matrix and
// glHistogram), which Mesa and most current drivers do not provide. These
// functions compute the same results and the pixels are drawn with
// glDrawPixels as before.

// Bytes per pixel of the loaded image, and the index of its red, green and
// blue bytes (the TGA loader returns BGR or BGRA on most files).
static int PixelBytes(void) {
  switch (eFormat) {
    case GL_BGRA_EXT:
    case GL_RGBA:
      return 4;
    case GL_LUMINANCE:
      return 1;
    default:
      return 3;
  }
}

static int RedIndex(void) {
  return (eFormat == GL_BGR_EXT || eFormat == GL_BGRA_EXT) ? 2 : 0;
}

static GLubyte ClampToByte(GLfloat f) {
  if (f < 0.0f) return 0;
  if (f > 255.0f) return 255;
  return (GLubyte)f;
}

// 3x3 convolution of each color channel, with the edge pixels repeated.
static void Convolve3x3(const GLubyte* pSrc, GLubyte* pDst,
                        const GLfloat kernel[3][3]) {
  int nBytes = PixelBytes();
  int nColor = (nBytes == 4) ? 3 : nBytes;  // alpha is left alone
  for (int y = 0; y < iHeight; y++) {
    for (int x = 0; x < iWidth; x++) {
      for (int c = 0; c < nBytes; c++) {
        if (c >= nColor) {
          pDst[(y * iWidth + x) * nBytes + c] =
              pSrc[(y * iWidth + x) * nBytes + c];
          continue;
        }
        GLfloat sum = 0.0f;
        for (int i = 0; i < 3; i++) {
          int sy = y + i - 1;
          if (sy < 0) sy = 0;
          if (sy >= iHeight) sy = iHeight - 1;
          for (int j = 0; j < 3; j++) {
            int sx = x + j - 1;
            if (sx < 0) sx = 0;
            if (sx >= iWidth) sx = iWidth - 1;
            sum += kernel[i][j] * pSrc[(sy * iWidth + sx) * nBytes + c];
          }
        }
        pDst[(y * iWidth + x) * nBytes + c] = ClampToByte(sum);
      }
    }
  }
}

// Luminance of one pixel, using the book's weights.
static GLubyte Luminance(const GLubyte* pPixel) {
  if (PixelBytes() == 1) return pPixel[0];
  int r = RedIndex();
  return ClampToByte(0.30f * pPixel[r] + 0.59f * pPixel[1] +
                     0.11f * pPixel[2 - r]);
}

// Replace each pixel's color with its luminance.
static void ToLuminance(GLubyte* pImageData) {
  int nBytes = PixelBytes();
  if (nBytes == 1) return;
  for (int i = 0; i < iWidth * iHeight; i++) {
    GLubyte* pPixel = pImageData + i * nBytes;
    GLubyte lum = Luminance(pPixel);
    pPixel[0] = pPixel[1] = pPixel[2] = lum;
  }
}

// Returns a newly allocated copy of the source image with the operation for
// the given render mode applied.
static GLubyte* ProcessImage(GLint iMode) {
  static GLfloat mSharpen[3][3] = {// Sharpen convolution kernel
                                   {0.0f, -1.0f, 0.0f},
                                   {-1.0f, 5.0f, -1.0f},
                                   {0.0f, -1.0f, 0.0f}};

  static GLfloat mEmboss[3][3] = {// Emboss convolution kernel
                                  {2.0f, 0.0f, 0.0f},
                                  {0.0f, -1.0f, 0.0f},
                                  {0.0f, 0.0f, -1.0f}};

  int nBytes = PixelBytes();
  int nColor = (nBytes == 4) ? 3 : nBytes;  // alpha is left alone
  size_t nSize = (size_t)iWidth * iHeight * nBytes;
  GLubyte* pOut = (GLubyte*)malloc(nSize);
  const GLubyte* pIn = (const GLubyte*)pImage;

  switch (iMode) {
    case 5:  // Sharpen image
      Convolve3x3(pIn, pOut, mSharpen);
      break;

    case 4:  // Emboss image, then take the luminance
      Convolve3x3(pIn, pOut, mEmboss);
      ToLuminance(pOut);
      break;

    case 3:  // Invert Image
      for (size_t i = 0; i < nSize; i++) {
        int c = (int)(i % nBytes);
        pOut[i] = (c < nColor) ? (GLubyte)(255 - pIn[i]) : pIn[i];
      }
      break;

    case 2:  // Brighten Image
      for (size_t i = 0; i < nSize; i++) {
        int c = (int)(i % nBytes);
        pOut[i] = (c < nColor) ? ClampToByte(1.25f * pIn[i]) : pIn[i];
      }
      break;

    case 1:  // Just do a plain old image copy
    default:
      for (size_t i = 0; i < nSize; i++) pOut[i] = pIn[i];
      break;
  }
  return pOut;
}

///////////////////////////////////////////////////////////////////////
// Called to draw scene
void RenderScene(void) {
  GLint i;             // Looping variable
  GLint iViewport[4];  // Viewport
  GLint iLargest;      // Largest histogram value

  static GLint histoGram[256];  // Storeage for histogram statistics

  // Clear the window with current clearing color
  glClear(GL_COLOR_BUFFER_BIT);

  // Current Raster Position always at bottom left hand corner of window
  glRasterPos2i(0, 0);
  glGetIntegerv(GL_VIEWPORT, iViewport);
  glPixelZoom((GLfloat)iViewport[2] / (GLfloat)iWidth,
              (GLfloat)iViewport[3] / (GLfloat)iHeight);

  // Do image operation, depending on rendermode index
  GLubyte* pProcessed = ProcessImage(iRenderMode);

  // Do the pixel draw
  glDrawPixels(iWidth, iHeight, eFormat, GL_UNSIGNED_BYTE, pProcessed);

  // Collect and draw histogram?
  if (bHistogram == GL_TRUE) {
    // 256 luminance values, using our conversion formula
    int nBytes = PixelBytes();
    for (i = 0; i < 256; i++) histoGram[i] = 0;
    for (i = 0; i < iWidth * iHeight; i++)
      histoGram[Luminance(pProcessed + i * nBytes)]++;

    // Find largest value for scaling graph down
    iLargest = 1;
    for (i = 0; i < 255; i++)
      if (iLargest < histoGram[i]) iLargest = histoGram[i];

    // White lines
    glColor3f(1.0f, 1.0f, 1.0f);
    glBegin(GL_LINE_STRIP);
    for (i = 0; i < 255; i++)
      glVertex2f((GLfloat)i,
                 (GLfloat)histoGram[i] / (GLfloat)iLargest * 128.0f);
    glEnd();

    bHistogram = GL_FALSE;
  }

  free(pProcessed);

  // Show our hard work...
  glutSwapBuffers();
}

void ChangeSize(int w, int h) {
  // Prevent a divide by zero, when window is too short
  // (you cant make a window of zero width).
  if (h == 0) h = 1;

  glViewport(0, 0, w, h);

  // Reset the coordinate system before modifying
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();

  // Set the clipping volume
  gluOrtho2D(0.0f, (GLfloat)w, 0.0, (GLfloat)h);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
}

/////////////////////////////////////////////////////////////
// Main program entrypoint
int main(int argc, char* argv[]) {
  glutInit(&argc, argv);
  glutInitDisplayMode(GLUT_RGB | GL_DOUBLE);
  glutInitWindowSize(600, 600);
  glutCreateWindow("OpenGL Imaging subset");

  glutReshapeFunc(ChangeSize);
  glutDisplayFunc(RenderScene);

  // Create the Menu and add choices
  glutCreateMenu(ProcessMenu);
  glutAddMenuEntry("Save Image", 0);
  glutAddMenuEntry("Raw Stretched Image", 1);
  glutAddMenuEntry("Increase Contrast", 2);
  glutAddMenuEntry("Invert Color", 3);
  glutAddMenuEntry("Emboss Image", 4);
  glutAddMenuEntry("Sharpen Image", 5);
  glutAddMenuEntry("Histogram", 6);

  glutAttachMenu(GLUT_RIGHT_BUTTON);

  SetupRC();  // Do setup

  glutMainLoop();  // Main program loop

  ShutdownRC();  // Do shutdown

  return 0;
}
