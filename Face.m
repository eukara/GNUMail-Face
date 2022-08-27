/*
**  Face.m
**
**  Copyright 2001-2006
** 
**  Author: Ludovic Marcotte <ludovic@Sophos.ca>
**
**  This program is free software; you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation; either version 2 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License
**  along with this program; if not, write to the Free Software
**  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#include "Face.h"

#include "NSUserDefaults+Extensions.h"
#include "Constants.h"

#include <setjmp.h>

//#include <compface.h>

@implementation Face

//
//
//
- (id) initWithResourcePath: (NSString *) theResourcePath
{
  self = [super init];
  
  stamp = [[NSImage alloc] initWithContentsOfFile: [NSString stringWithFormat: @"%@/stamp.tiff", theResourcePath]];
  image = nil;
 
  return self;
}


//
//
//
- (void) dealloc
{
  NSDebugLog(@"Face: -dealloc");

  RELEASE(stamp);
  TEST_RELEASE(image);

  [super dealloc];
}


//
//
//
- (void) setImage: (NSImage *) theImage
{
  if ( theImage )
    {
      RETAIN(theImage);
      RELEASE(image);
      image = theImage;
    }
  else
    {
      NSDebugLog(@"Face: -setImage. attempted to set a nil image.");
      DESTROY(image);
    }
}


//
//
//
- (NSRect) frame
{
  if ( !image )
    {
      return NSZeroRect;
    }

  return NSMakeRect(0,0,81,83);
}


//
// Implementation of the inherited method from NSView
//
- (void) drawRect: (NSRect) theRect
{
  float width, height, ratio;
  // Safe guard.
  if ( !image )
    {
      return;
    }

  // We draw our stamp
  [stamp dissolveToPoint: NSMakePoint(theRect.origin.x,theRect.origin.y) 
	 fraction: 1.0];

  // We scale the image properly before compositing it
  [image setScalesWhenResized: YES];

  // We get the right ratio, based on the maximum size of the width or the heigh
  width = [image size].width;
  height = [image size].height;

  if ( width > height )
    {
      ratio =  60.0/width;
      width = 60.0;
      height = height*ratio;
    }
  else
    {
      ratio =  60.0/height;
      height = 60.0;
      width = width*ratio;
    }

  [image setSize: NSMakeSize(width,height)];
  [image compositeToPoint: NSMakePoint(theRect.origin.x+10,theRect.origin.y-13) 
	 operation: NSCompositeSourceOver];
}

@end


//
// This code has been created by Carl Edman <cedman@capitalist.princeton.edu>
// (C) Copyright 1995, but otherwise this file is perfect freeware.
//
// The Compface has been created by James Ashton - Sydney University - June 1990.
// Written 11th November 1989.
//
// Permission is given to distribute these sources, as long as the
// copyright messages are not removed, and no monies are exchanged. 
//
// No responsibility is taken for any errors on inaccuracies inherent
// either to the comments or the code of this program, but if reported
// to me, then an attempt will be made to fix them.
//
// This code has been adapted to Cocoa by Dominik Westner <software@nikwest.de>
//
//
#define EMBEDDED

/* need to know how many bits per hexadecimal digit for io */
#define BITSPERDIG 4
#ifndef EMBEDDED
static char HexDigits[]="0123456789ABCDEF";
#endif

/* define the face size - 48x48x1 */
#define WIDTH 48
#define HEIGHT WIDTH

/* total number of pixels and digits */
#define PIXELS (WIDTH * HEIGHT)
#define DIGITS (PIXELS / BITSPERDIG)

/* internal face representation - 1 char per pixel is faster */
static char F[PIXELS];

/* output formatting word lengths and line lengths */
#define DIGSPERWORD 4
#define WORDSPERLINE (WIDTH / DIGSPERWORD / BITSPERDIG)

/* compressed output uses the full range of printable characters.
 * in ascii these are in a contiguous block so we just need to know
 * the first and last.  The total number of printables is needed too */
#define FIRSTPRINT '!'
#define LASTPRINT '~'
#define NUMPRINTS (LASTPRINT - FIRSTPRINT + 1)

/* output line length for compressed data */
#define MAXLINELEN 70

/* Portable, very large unsigned integer arithmetic is needed.
 * Implementation uses arrays of WORDs.  COMPs must have at least
 * twice as many bits as WORDs to handle intermediate results */
#define WORD unsigned char
#define COMP unsigned long
#define BITSPERWORD 8
#define WORDCARRY (1 << BITSPERWORD)
#define WORDMASK (WORDCARRY - 1)
#define MAXWORDS ((PIXELS * 2 + BITSPERWORD - 1) / BITSPERWORD)

typedef struct bigint
{
   int b_words;
   WORD b_word[MAXWORDS];
} BigInt;

static BigInt B;

/* This is the guess the next pixel table.  Normally there are 12 neighbour
 * pixels used to give 1<<12 cases but in the upper left corner lesser
 * numbers of neighbours are available, leading to 6231 different guesses */
typedef struct guesses
{
   char g_00[1<<12];
   char g_01[1<<7];
   char g_02[1<<2];
   char g_10[1<<9];
   char g_20[1<<6];
   char g_30[1<<8];
   char g_40[1<<10];
   char g_11[1<<5];
   char g_21[1<<3];
   char g_31[1<<5];
   char g_41[1<<6];
   char g_12[1<<1];
   char g_22[1<<0];
   char g_32[1<<2];
   char g_42[1<<2];
} Guesses;

/* data.h was established by sampling over 1000 faces and icons */
static const Guesses G =
{
   {
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 1, 1,
      0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1,
      0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1,
      0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1,
      0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 1, 1, 1,
      1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
      1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1,
      0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 0,
      0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1,
      0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 0, 0, 1, 1, 1,
      1, 1, 0, 1, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1,
      0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1,
      1, 0, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1,
      0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 1,
      0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1,
      0, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1,
      0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 1,
      1, 1, 0, 1, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1,
      0, 1, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1,
      0, 1, 0, 1, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 0, 1,
      0, 0, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1,
      1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1,
      0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1,
      0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 1, 0,
      0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1,
      0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 1, 0, 1, 1, 1,
      1, 0, 0, 1, 0, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1,
      0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1,
      0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1,
      0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1,
      1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1,
      0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1,
      0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0,
      0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0,
      0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
      0, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1,
      0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0,
      0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,
      1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1,
      1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1,
      0, 1, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1,
      0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1,
      1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1,
      0, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 0, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1,
      0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1,
      0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0,
      0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
      0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
      1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1,
      0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1,
      1, 0, 1, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
      0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0,
      0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 0, 1, 0, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1,
      1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 0,
      0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1,
      1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 1, 1, 1,
      0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1,
      1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1,
      0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0,
      0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1,
      0, 1, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1,
      1, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0,
      0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 1, 1,
      0, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1,
      0, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1,
      0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 1, 0, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1,
      1, 1, 0, 1, 1, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1,
      0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1,
      0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1,
      0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 1, 0, 0, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 0,
      0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0,
      0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
      1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1,
      0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0,
      0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 0, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0,
      1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 1,
      1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1,
      0, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1,
      0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1,
      1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0,
      1, 0, 1, 0, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1,
      0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0,
      1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1,
      0, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 0, 0, 1, 1, 0,
      1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 0,
      1, 0, 0, 0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 1,
      0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1,
      1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0,
      1, 0, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1,
      0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   },
   {
      0, 0, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 0, 1, 1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1,
      0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1,
      0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1,
      1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 1,
      0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
   },
   {
      0, 1, 0, 1, 
   },
   {
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
      0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
      1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 
      1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 
      0, 0, 0, 1, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 
      0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 
      0, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 
      0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 
      0, 0, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 
      0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 
      0, 1, 0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 
      0, 0, 0, 1, 0, 1, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
      0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 
      0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 
      0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
      0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 
      0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 
      0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 
      0, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 
      1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
      0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 
      0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 
      0, 0, 0, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 
      1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 0, 0, 
      0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 
      0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 
      0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
   },
   {
      0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
      0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 
      0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 1, 0, 
      1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 
   },
   {
      0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 
      0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 
      0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 
      0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 
      0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 
      0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 
      0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 
      0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 
      0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 
      0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 1, 
      0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 1, 
      0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 1, 
      0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 
      0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 
      0, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 
      0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 
   },
   {
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 0, 
      1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 
      0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 
      0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 1, 1, 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 
      0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 
      1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 
      0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 
      1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
      0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 
      0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 
      0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 1, 1, 1, 0, 1, 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 
      0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 
      0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 
      0, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 
      0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
      1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
      0, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
      0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 
      1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
      1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 
      0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 
      0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 
      0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 
      0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 
      0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 
      0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
      0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 1, 
      0, 0, 0, 0, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 
      0, 1, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
      0, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
      0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
      0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 
      0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 
      0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 
      0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
      0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 
      0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 
      0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 
      0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 
      0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 
      0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 
      0, 0, 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 
      0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
      0, 1, 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 0, 1, 
      0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
   },
   {
      0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 
      0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 
   },
   {
      0, 0, 0, 1, 0, 1, 1, 1, 
   },
   {
      0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 
      0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 
   },
   {
      0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 
      0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 1, 
      0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 
      0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
   },
   {
      0, 1, 
   },
   {
      0, 
   },
   {
      0, 0, 0, 1, 
   },
   {
      0, 0, 0, 1, 
   }
};

/* Data of varying probabilities are encoded by a value in the range 0 - 255.
 * The probability of the data determines the range of possible encodings.
 * Offset gives the first possible encoding of the range */
typedef struct prob
{
   WORD p_range;
   WORD p_offset;
} Prob;

/* A stack of probability values */
static const Prob *ProbBuf[PIXELS * 2];
static int NumProbs=0;

/* Each face is encoded using 9 octrees of 16x16 each.  Each level of the
 * trees has varying probabilities of being white, grey or black.
 * The table below is based on sampling many faces */

#define BLACK 0
#define GREY 1
#define WHITE 2

static const Prob levels[4][3] =
{
   {{  1, 255}, {251,   0}, {   4, 251}}, /* Top of tree almost always grey */
   {{  1, 255}, {200,   0}, {  55, 200}},
   {{ 33, 223}, {159,   0}, {  64, 159}},
   {{131,   0}, {  0,   0}, { 125, 131}}  /* Grey disallowed at bottom */
};

/* At the bottom of the octree 2x2 elements are considered black if any
 * pixel is black.  The probabilities below give the distribution of the
 * 16 possible 2x2 patterns.  All white is not really a possibility and
 * has a probability range of zero.  Again, experimentally derived data */
static const Prob freqs[16] =
{
   {0, 0}, {38, 0}, {38, 38}, {13, 152}, {38, 76}, {13, 165}, {13, 178},
   {6, 230}, {38, 114}, {13, 191}, {13, 204}, {6, 236}, {13, 217},
   {6, 242}, {5, 248}, {3, 253}
};

/* successful completion */
#define ERR_OK          0
/* completed OK but some input was ignored */
#define ERR_EXCESS      1
/* insufficient input.  Bad face format? */
#define ERR_INSUFF     -1
/* Arithmetic overflow or buffer overflow */
#define ERR_INTERNAL   -2

#define GEN(g) F[h] ^= G.g[k]; break

static jmp_buf comp_env;
#ifndef EMBEDDED
static int status;
#endif

static int AllBlack(char *, int, int);
static int AllWhite(char *, int, int);
static int BigPop(const Prob *);
static int Same(char *, int, int);

static void BigAdd(unsigned char);
static void BigClear(void);
static void BigDiv(unsigned char, unsigned char *);
static void BigMul(unsigned char);
static void BigRead(const char *);
static void Compress(char *, int, int, int);
static void Gen(char *);
static void PopGreys(char *, int, int);
static void PushGreys(char *, int, int);
static void RevPush(const Prob *);
static void UnCompAll(const char *);
static void UnCompress(char *, int, int, int);
static void UnGenFace(void);
#ifndef EMBEDDED
static void BigPrint(void);
static void BigSub(unsigned char);
static void ReadFace(char *);
static void WriteFace(char *);
#endif

static void RevPush(const Prob *p)
{
   if (NumProbs >= PIXELS * 2 - 1)
      longjmp(comp_env, ERR_INTERNAL);
   ProbBuf[NumProbs++] = p;
}
 
static int BigPop(const Prob *p)
{
   static WORD tmp;
   int i;
   
   BigDiv(0, &tmp);
   i = 0;
   while ((tmp < p->p_offset) || (tmp >= p->p_range + p->p_offset))
   {
      p++;
      i++;
   }
   BigMul(p->p_range);
   BigAdd(tmp - p->p_offset);
   return i;
}

#ifndef EMBEDDED
/* Print a BigInt in HexaDecimal */
static void BigPrint(void)
{
   int i, c, count;
   WORD *w;

   count = 0;
   w = B.b_word + (i = B.b_words);
   while (i--)
   {
      w--;
      c = *((*w >> 4) + HexDigits);
      putc(c, stderr);
      c = *((*w & 0xf) + HexDigits);
      putc(c, stderr);
      if (++count >= 36)
      {
         putc('\\', stderr);
         putc('\n', stderr);
         count = 0;
      }
   }
   putc('\n', stderr);
}
#endif

/* Divide B by a storing the result in B and the remainder in the word
 * pointer to by r */
static void BigDiv(WORD a, WORD *r)
{
   int i;
   WORD *w;
   COMP c, d;

   a &= WORDMASK;
   if ((a == 1) || (B.b_words == 0))
   {
      *r = 0;
      return;
   }
   if (a == 0)	/* treat this as a == WORDCARRY */
   {			/* and just shift everything right a WORD */
      i = --B.b_words;
      w = B.b_word;
      *r = *w;
      while (i--)
      {
         *w = *(w + 1);
         w++;
      }
      *w = 0;
      return;
   }
   w = B.b_word + (i = B.b_words);
   c = 0;
   while (i--)
   {
      c <<= BITSPERWORD;
      c += (COMP)*--w;
      d = c / (COMP)a;
      c = c % (COMP)a;
      *w = (WORD)(d & WORDMASK);
   }
   *r = c;
   if (B.b_word[B.b_words - 1] == 0)
      B.b_words--;
}

/* Multiply a by B storing the result in B */
static void BigMul(WORD a)
{
   int i;
   WORD *w;
   COMP c;
   
   a &= WORDMASK;
   if ((a == 1) || (B.b_words == 0))
      return;
   if (a == 0)	/* treat this as a == WORDCARRY */
   {			/* and just shift everything left a WORD */
      if ((i = B.b_words++) >= MAXWORDS - 1)
         longjmp(comp_env, ERR_INTERNAL);
      w = B.b_word + i;
      while (i--)
      {
         *w = *(w - 1);
         w--;
      }
      *w = 0;
      return;
   }
   i = B.b_words;
   w = B.b_word;
   c = 0;
   while (i--)
   {
      c += (COMP)*w * (COMP)a;
      *(w++) = (WORD)(c & WORDMASK);
      c >>= BITSPERWORD;
   }
   if (c)
   {
      if (B.b_words++ >= MAXWORDS)
         longjmp(comp_env, ERR_INTERNAL);
      *w = (COMP)(c & WORDMASK);
   }
}

#ifndef EMBEDDED
/* Subtract a from B storing the result in B */
static void BigSub(WORD a)
{
   int i;
   WORD *w;
   COMP c;
   
   a &= WORDMASK;
   if (a == 0)
      return;
   i = 1;
   w = B.b_word;
   c = (COMP)*w - (COMP)a;
   *w = (WORD)(c & WORDMASK);
   while (c & WORDCARRY)
   {
      if (i >= B.b_words)
         longjmp(comp_env, ERR_INTERNAL);
      c = (COMP)*++w - 1;
      *w = (WORD)(c & WORDMASK);
      i++;
   }
   if ((i == B.b_words) && (*w == 0) && (i > 0))
      B.b_words--;
}
#endif

/* Add to a to B storing the result in B */
static void BigAdd(WORD a)
{
   int i;
   WORD *w;
   COMP c;
   
   a &= WORDMASK;
   if (a == 0)
      return;
   i = 0;
   w = B.b_word;
   c = a;
   while ((i < B.b_words) && c)
   {
      c += (COMP)*w;
      *w++ = (WORD)(c & WORDMASK);
      c >>= BITSPERWORD;
      i++;
   }
   if ((i == B.b_words) && c)
   {
      if (B.b_words++ >= MAXWORDS)
         longjmp(comp_env, ERR_INTERNAL);
      *w = (COMP)(c & WORDMASK);
   }
}

static void BigClear(void)
{
   B.b_words = 0;
}

static int Same(char *f, int wid, int hei)
{
   char val, *row;
   int x;
   
   val = *f;
   while (hei--)
   {
      row = f;
      x = wid;
      while (x--)
         if (*(row++) != val)
            return(0);
      f += WIDTH;
   }
   return 1;
}

static int AllBlack(char *f, int wid, int hei)
{
   if (wid > 3)
   {
      wid /= 2;
      hei /= 2;
      return (AllBlack(f, wid, hei) && AllBlack(f + wid, wid, hei) &&
              AllBlack(f + WIDTH * hei, wid, hei) &&
              AllBlack(f + WIDTH * hei + wid, wid, hei));
   }
   else
      return (*f || *(f + 1) || *(f + WIDTH) || *(f + WIDTH + 1));
}

static int AllWhite(char *f, int wid, int hei)
{
   return ((*f == 0) && Same(f, wid, hei));
}

static void PopGreys(char *f, int wid, int hei)
{
   if (wid > 3)
   {
      wid /= 2;
      hei /= 2;
      PopGreys(f, wid, hei);
      PopGreys(f + wid, wid, hei);
      PopGreys(f + WIDTH * hei, wid, hei);
      PopGreys(f + WIDTH * hei + wid, wid, hei);
   }
   else
   {
      wid = BigPop(freqs);
      if (wid & 1)
         *f = 1;
      if (wid & 2)
         *(f + 1) = 1;
      if (wid & 4)
         *(f + WIDTH) = 1;
      if (wid & 8)
         *(f + WIDTH + 1) = 1;
   }
}

static void PushGreys(char *f, int wid, int hei)
{
   if (wid > 3)
   {
      wid /= 2;
      hei /= 2;
      PushGreys(f, wid, hei);
      PushGreys(f + wid, wid, hei);
      PushGreys(f + WIDTH * hei, wid, hei);
      PushGreys(f + WIDTH * hei + wid, wid, hei);
   }
   else
      RevPush(freqs + *f + 2 * *(f + 1) + 4 * *(f + WIDTH) +
              8 * *(f + WIDTH + 1));
}

static void UnCompress(char *f, int wid, int hei, int lev)
{
   switch (BigPop(&levels[lev][0]))
   {
    case WHITE :
       return;
    case BLACK :
       PopGreys(f, wid, hei);
       return;
    default :
       wid /= 2;
       hei /= 2;
       lev++;
       UnCompress(f, wid, hei, lev);
       UnCompress(f + wid, wid, hei, lev);
       UnCompress(f + hei * WIDTH, wid, hei, lev);
       UnCompress(f + wid + hei * WIDTH, wid, hei, lev);
       return;
   }
}

static void Compress(char *f, int wid, int hei, int lev)
{
   if (AllWhite(f, wid, hei))
   {
      RevPush(&levels[lev][WHITE]);
      return;
   }
   if (AllBlack(f, wid, hei))
   {
      RevPush(&levels[lev][BLACK]);
      PushGreys(f, wid, hei);
      return;
   }
   RevPush(&levels[lev][GREY]);
   wid /= 2;
   hei /= 2;
   lev++;
   Compress(f, wid, hei, lev);
   Compress(f + wid, wid, hei, lev);
   Compress(f + hei * WIDTH, wid, hei, lev);
   Compress(f + wid + hei * WIDTH, wid, hei, lev);
}

static void UnCompAll(const char *fbuf)
{
   char *p;
   
   BigClear();
   BigRead(fbuf);
   p = F;
   while (p < F + PIXELS)
      *(p++) = 0;
   UnCompress(F, 16, 16, 0);
   UnCompress(F + 16, 16, 16, 0);
   UnCompress(F + 32, 16, 16, 0);
   UnCompress(F + WIDTH * 16, 16, 16, 0);
   UnCompress(F + WIDTH * 16 + 16, 16, 16, 0);
   UnCompress(F + WIDTH * 16 + 32, 16, 16, 0);
   UnCompress(F + WIDTH * 32, 16, 16, 0);
   UnCompress(F + WIDTH * 32 + 16, 16, 16, 0);
   UnCompress(F + WIDTH * 32 + 32, 16, 16, 0);
}

static void BigRead(const char *fbuf)
{
   int c;
   
   while ((c=*fbuf++) != '\0')
   {
      if ((c < FIRSTPRINT) || (c > LASTPRINT)) continue;
      BigMul(NUMPRINTS);
      BigAdd((WORD)(c - FIRSTPRINT));
   }
}

#ifndef EMBEDDED
static void ReadFace(char *fbuf)
{
   int c, i;
   char *s, *t;
   
   t = s = fbuf;
   for(i = strlen(s); i > 0; i--)
   {
      c = (int)*(s++);
      if ((c >= '0') && (c <= '9'))
      {
         if (t >= fbuf + DIGITS)
	 {
            status = ERR_EXCESS;
            break;
	 }
         *(t++) = c - '0';
      }
      else if ((c >= 'A') && (c <= 'F'))
      {
         if (t >= fbuf + DIGITS)
	 {
            status = ERR_EXCESS;
            break;
	 }
         *(t++) = c - 'A' + 10;
      }
      else if ((c >= 'a') && (c <= 'f'))
      {
         if (t >= fbuf + DIGITS)
	 {
            status = ERR_EXCESS;
            break;
	 }
         *(t++) = c - 'a' + 10;
      }
      else if (((c == 'x') || (c == 'X')) && (t > fbuf) && (*(t-1) == 0))
         t--;
   }
   if (t < fbuf + DIGITS)
      longjmp(comp_env, ERR_INSUFF);
   s = fbuf;
   t = F;
   c = 1 << (BITSPERDIG - 1);
   while (t < F + PIXELS)
   {
      *(t++) = (*s & c) ? 1 : 0;
      if ((c >>= 1) == 0)
      {
         s++;
         c = 1 << (BITSPERDIG - 1);
      }
   }
}

static void WriteFace(char *fbuf)
{
   char *s, *t;
   int i, bits, digits, words;
   
   s = F;
   t = fbuf;
   bits = digits = words = i = 0;
   while (s < F + PIXELS)
   {
      if ((bits == 0) && (digits == 0))
      {
         *(t++) = '0';
         *(t++) = 'x';
      }
      if (*(s++))
         i = i * 2 + 1;
      else
         i *= 2;
      if (++bits == BITSPERDIG)
      {
         *(t++) = *(i + HexDigits);
         bits = i = 0;
         if (++digits == DIGSPERWORD)
	 {
            *(t++) = ',';
            digits = 0;
            if (++words == WORDSPERLINE)
	    {
               *(t++) = '\n';
               words = 0;
	    }
	 }
      }
   }
   *(t++) = '\0';
}
#endif

static void Gen(char *f)
{
   int m, l, k, j, i, h;
   
   for (j = 0; j < HEIGHT;  j++)
   {
      for (i = 0; i < WIDTH;  i++)
      {
         h = i + j * WIDTH;
         k = 0;
         for (l = i - 2; l <= i + 2; l++)
            for (m = j - 2; m <= j; m++)
	    {
               if ((l >= i) && (m == j))
                  continue;
               if ((l > 0) && (l <= WIDTH) && (m > 0))
                  k = *(f + l + m * WIDTH) ? k * 2 + 1 : k * 2;
	    }
         switch (i)
	 {
          case 1 :
            switch (j)
	    {
              case 1 : GEN(g_22);
              case 2 : GEN(g_21);
              default : GEN(g_20);
	    }
            break;
          case 2 :
            switch (j)
	    {
               case 1 : GEN(g_12);
               case 2 : GEN(g_11);
               default : GEN(g_10);
	    }
            break;
          case WIDTH - 1 :
            switch (j)
	    {
               case 1 : GEN(g_42);
               case 2 : GEN(g_41);
               default : GEN(g_40);
	    }
            break;
          case WIDTH :
            switch (j)
	    {
               case 1 : GEN(g_32);
               case 2 : GEN(g_31);
               default : GEN(g_30);
	    }
            break;
          default :
            switch (j)
	    {
               case 1 : GEN(g_02);
               case 2 : GEN(g_01);
               default : GEN(g_00);
	    }
            break;
	 }
      }
   }
}

static void UnGenFace(void)
{
   Gen(F);
}

@implementation NSImage(XFace)

- (NSImage *) initWithXFaceString:(NSString *)xfaceString size:(NSSize)size
{
   int x,y,avg;
   int basex,basey;
   unsigned char *data;
   id bitrep;
   const char *face;

   [self initWithSize:size];

   switch (setjmp(comp_env))
   {
    case ERR_INSUFF:   /* insufficient input.  Bad face format? */
      NSLog(@"Insufficient input decoding X face.");
      return nil;
    case ERR_INTERNAL: /* Arithmetic overflow or buffer overflow */
      NSLog(@"Internal error in decoding X face.");
      return nil;
    case ERR_EXCESS:   /* completed OK but some input was ignored */
      NSLog(@"Excessive data in X face string ignored.");
    case ERR_OK:       /* successful completion */
    default:
      break;
   }

   if(![xfaceString length]) {
       NSLog(@"Cannot create NSImage from empty xFace String");
       return nil;
   }

   face = [xfaceString cString];
   UnCompAll(face);
   UnGenFace();

   bitrep=[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:size.width pixelsHigh:size.height bitsPerSample:1 samplesPerPixel:1 hasAlpha:NO isPlanar:YES colorSpaceName:NSDeviceWhiteColorSpace bytesPerRow:0 bitsPerPixel:0];

   data=[bitrep bitmapData];

   basex=(size.width-WIDTH)/2;
   basey=(size.height-HEIGHT)/2;

   /* This double counts the corners, but that is ok, right ?
      In a heuristic anyway */
   avg=0;
   for(x=0;x<WIDTH;x++)  avg += F[0*WIDTH+x] + F[(HEIGHT-1)*WIDTH+x];
   for(y=0;y<HEIGHT;y++) avg += F[y*WIDTH+0] + F[y*WIDTH+(WIDTH-1)];
   avg=(avg > (WIDTH+HEIGHT));
   
   for(y=0;y<size.height;y++) for(x=0;x<size.width;x++)
   {
      int pos=x+y*size.width;
      
      if (((x>=basex) && (x<basex+WIDTH) && (y>=basey) && (y<basey+HEIGHT)) ?
          F[(y-basey)*WIDTH+(x-basex)] : avg)
	data[pos/8] &= ~(1<<(7-pos%8));
      else
	data[pos/8] |= 1<<(7-pos%8);
   }

   [self addRepresentation:bitrep];
   
   return self;
}

- (NSImage *) initWithXFaceString:(NSString *)xface
{
   return [self initWithXFaceString:xface size:NSMakeSize(WIDTH,HEIGHT)];
}
@end // NSImage(XFace)
