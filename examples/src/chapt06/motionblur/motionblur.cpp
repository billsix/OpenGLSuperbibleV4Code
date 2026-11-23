// MotionBlur.cpp
// OpenGL SuperBible
// Demonstrates Motion Blur with the Accumulation buffer
// Program by Richard S. Wright Jr.

#include "../../shared/gltools.h"  // OpenGL toolkit

#include <math.h>
#include <stdio.h>

// Light and material Data
GLfloat fLightPos[4] = {-100.0f, 100.0f, 50.0f, 1.0f};  // Point source
GLfloat fLightPosMirror[4] = {-100.0f, -100.0f, 50.0f, 1.0f};
GLfloat fNoLight[] = {0.0f, 0.0f, 0.0f, 0.0f};
GLfloat fLowLight[] = {0.25f, 0.25f, 0.25f, 1.0f};
GLfloat fBrightLight[] = {1.0f, 1.0f, 1.0f, 1.0f};

GLfloat yRot = 45.0f;

// Many drivers (Mesa, notably) give a window no accumulation buffer. When
// bHasAccum is false the same weighted sum is built with two textures and
// additive blending: each pass is copied into texPass, and the running sum is
// rebuilt in the color buffer from texSum and texPass, then copied to texSum.
GLboolean bHasAccum = GL_TRUE;
GLuint texPass = 0;
GLuint texSum = 0;
GLint nWidth = 1;
GLint nHeight = 1;

//////////////////////////////////////////////////////////////////
// This function does any needed initialization on the rendering
// context.
void SetupRC() {
  // Grayish background
  glClearColor(fLowLight[0], fLowLight[1], fLowLight[2], fLowLight[3]);

  // Cull backs of polygons
  glCullFace(GL_BACK);
  glFrontFace(GL_CCW);
  glEnable(GL_CULL_FACE);
  glEnable(GL_DEPTH_TEST);

  // Setup light parameters
  glLightModelfv(GL_LIGHT_MODEL_AMBIENT, fNoLight);
  glLightfv(GL_LIGHT0, GL_AMBIENT, fLowLight);
  glLightfv(GL_LIGHT0, GL_DIFFUSE, fBrightLight);
  glLightfv(GL_LIGHT0, GL_SPECULAR, fBrightLight);
  glLightfv(GL_LIGHT0, GL_POSITION, fLightPos);

  glEnable(GL_LIGHTING);
  glEnable(GL_LIGHT0);

  // Mostly use material tracking
  glEnable(GL_COLOR_MATERIAL);
  glColorMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE);
  glMateriali(GL_FRONT, GL_SHININESS, 128);
}

///////////////////////////////////////////////////////////
// Draw the ground as a series of triangle strips. The
// shading model and colors are set such that we end up
// with a black and white checkerboard pattern.
void DrawGround(void) {
  GLfloat fExtent = 20.0f;
  GLfloat fStep = 0.5f;
  GLfloat y = 0.0f;
  GLfloat fColor;
  GLfloat iStrip, iRun;
  GLint iBounce = 0;

  glShadeModel(GL_FLAT);
  for (iStrip = -fExtent; iStrip <= fExtent; iStrip += fStep) {
    glBegin(GL_TRIANGLE_STRIP);
    for (iRun = fExtent; iRun >= -fExtent; iRun -= fStep) {
      if ((iBounce % 2) == 0)
        fColor = 1.0f;
      else
        fColor = 0.0f;

      glColor4f(fColor, fColor, fColor, 0.5f);
      glVertex3f(iStrip, y, iRun);
      glVertex3f(iStrip + fStep, y, iRun);

      iBounce++;
    }
    glEnd();
  }
  glShadeModel(GL_SMOOTH);
}

/////////////////////////////////////////////////////////////
// Draw the ground and the revolving sphere
void DrawGeometry(void) {
  // Clear the window with current clearing color
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  glPushMatrix();
  DrawGround();

  // Place the moving sphere
  glColor3f(1.0f, 0.0f, 0.0f);
  glTranslatef(0.0f, 0.5f, -3.5f);
  glRotatef(-(yRot * 2.0f), 0.0f, 1.0f, 0.0f);
  glTranslatef(1.0f, 0.0f, 0.0f);
  glutSolidSphere(0.1f, 17, 9);
  glPopMatrix();
}

///////////////////////////////////////////////////////////////////////
// Texture-based replacement for the accumulation buffer, used when the
// window has none.

// Copy the color buffer into a texture of the window's size.
void CopyColorBufferTo(GLuint texture) {
  glBindTexture(GL_TEXTURE_2D, texture);
  glCopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 0, 0, nWidth, nHeight);
}

// Prepare to add full-window textured quads to a black color buffer.
void BeginTextureSum(void) {
  glPushAttrib(GL_ENABLE_BIT | GL_CURRENT_BIT | GL_COLOR_BUFFER_BIT |
               GL_TEXTURE_BIT);
  glDisable(GL_LIGHTING);
  glDisable(GL_DEPTH_TEST);
  glDisable(GL_CULL_FACE);
  glEnable(GL_TEXTURE_2D);
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
  glEnable(GL_BLEND);
  glBlendFunc(GL_ONE, GL_ONE);
  glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  glMatrixMode(GL_PROJECTION);
  glPushMatrix();
  glLoadIdentity();
  glMatrixMode(GL_MODELVIEW);
  glPushMatrix();
  glLoadIdentity();
}

void EndTextureSum(void) {
  glMatrixMode(GL_PROJECTION);
  glPopMatrix();
  glMatrixMode(GL_MODELVIEW);
  glPopMatrix();
  glPopAttrib();
}

// Add weight * texture to every pixel of the color buffer. GL_MODULATE
// multiplies each texel by the current color.
void AddTexture(GLuint texture, GLfloat weight) {
  glBindTexture(GL_TEXTURE_2D, texture);
  glColor4f(weight, weight, weight, 1.0f);
  glBegin(GL_QUADS);
  glTexCoord2f(0.0f, 0.0f);
  glVertex2f(-1.0f, -1.0f);
  glTexCoord2f(1.0f, 0.0f);
  glVertex2f(1.0f, -1.0f);
  glTexCoord2f(1.0f, 1.0f);
  glVertex2f(1.0f, 1.0f);
  glTexCoord2f(0.0f, 1.0f);
  glVertex2f(-1.0f, 1.0f);
  glEnd();
}

///////////////////////////////////////////////////////////////////////
// Called to draw scene. The world is drawn multiple times with each
// frame blended with the last. The current rotation is advanced each
// time to create the illusion of motion blur.
void RenderScene(void) {
  GLfloat fPass;
  GLfloat fPasses = 10.0f;

  // Set the current rotation back a few degrees
  yRot = 35.0f;

  for (fPass = 0.0f; fPass < fPasses; fPass += 1.0f) {
    yRot += .75f;  // 1.0f / (fPass+1.0f);

    // Draw sphere
    DrawGeometry();

    // Accumulate to back buffer
    GLfloat fWeight = (fPass == 0.0f) ? 0.5f : 0.5f * (1.0f / fPasses);
    if (bHasAccum) {
      if (fPass == 0.0f)
        glAccum(GL_LOAD, fWeight);
      else
        glAccum(GL_ACCUM, fWeight);
    } else {
      // sum = sum + weight * pass, rebuilt in the color buffer
      CopyColorBufferTo(texPass);
      BeginTextureSum();
      if (fPass > 0.0f) AddTexture(texSum, 1.0f);
      AddTexture(texPass, fWeight);
      EndTextureSum();
      CopyColorBufferTo(texSum);
    }
  }

  // copy accumulation buffer to color buffer and
  // do the buffer Swap. Without an accumulation buffer the color buffer
  // already holds the sum.
  if (bHasAccum) glAccum(GL_RETURN, 1.0f);
  glutSwapBuffers();
}

void ChangeSize(int w, int h) {
  GLfloat fAspect;

  // Prevent a divide by zero, when window is too short
  // (you cant make a window of zero width).
  if (h == 0) h = 1;

  glViewport(0, 0, w, h);

  // The replacement textures match the window.
  nWidth = w;
  nHeight = h;
  if (!bHasAccum) {
    GLuint textures[2] = {texPass, texSum};
    for (int i = 0; i < 2; i++) {
      glBindTexture(GL_TEXTURE_2D, textures[i]);
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, w, h, 0, GL_RGBA,
                   GL_UNSIGNED_BYTE, NULL);
    }
  }

  fAspect = (GLfloat)w / (GLfloat)h;

  // Reset the coordinate system before modifying
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();

  // Set the clipping volume
  gluPerspective(35.0f, fAspect, 1.0f, 50.0f);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  glTranslatef(0.0f, -0.4f, 0.0f);
}

/////////////////////////////////////////////////////////////
// Main program entrypoint
int main(int argc, char* argv[]) {
  glutInit(&argc, argv);
  glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH | GLUT_ACCUM);
  // Creating a window with no matching accumulation visual is fatal in
  // freeglut, so ask first and fall back to the texture-based replacement.
  if (!glutGet(GLUT_DISPLAY_MODE_POSSIBLE)) {
    printf("No accumulation buffer; blending textures instead.\n");
    bHasAccum = GL_FALSE;
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH);
  }
  glutInitWindowSize(800, 600);
  glutCreateWindow("Motion Blur with the Accumulation Buffer");
  glutReshapeFunc(ChangeSize);
  glutDisplayFunc(RenderScene);

  SetupRC();
  if (!bHasAccum) {
    glGenTextures(1, &texPass);
    glGenTextures(1, &texSum);
    GLuint textures[2] = {texPass, texSum};
    for (int i = 0; i < 2; i++) {
      glBindTexture(GL_TEXTURE_2D, textures[i]);
      // one level, no mipmaps, so the default filter must change
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    }
  }
  glutMainLoop();

  return 0;
}
