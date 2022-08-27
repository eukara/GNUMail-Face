/*
**  Face.h
**
**  Copyright 2001-2004
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

#ifndef _GNUMail_H_Face
#define _GNUMail_H_Face

#import <AppKit/AppKit.h>

@interface Face : NSView
{
  NSImage *image, *stamp;
}

- (id) initWithResourcePath: (NSString *) theResourcePath;

- (void) setImage: (NSImage *) theImage;

@end


//
// This code has been created by Carl Edman <cedman@capitalist.princeton.edu>
// (C) Copyright 1995, but otherwise this file is perfect freeware.
//
@interface NSImage (XFace)

- (NSImage *) initWithXFaceString:(NSString *)xface;
- (NSImage *) initWithXFaceString:(NSString *)xface size:(NSSize)s;

@end

#endif // _GNUMail_H_Face
