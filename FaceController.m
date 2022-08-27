/*
**  FaceController.m
**
**  Copyright (c) 2001-2004
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
**  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include "FaceController.h"

#include "Constants.h"
#include "Face.h"
#include "GNUMail.h"
#include "MailHeaderCell.h"
#include "MailWindowController.h"

#include <Pantomime/CWMessage.h>

static FaceController *singleInstance = nil;

//
// Rationale:
//
// The behavior of the cache is relatively simple. The key is always a NSString
// holding the value of the URL. The value to which the key points to can be
// either a NSImage or a (NSURL, NSURLHandle) pair.
//
// When it's a (NSURL, NSURLHandle) pair, the image is being loaded from the website where
// the X-Image-URL resides and we must wait for completion (success or a failure)
// before showing the image.
//
// If it's a NSImage, the image was sucessfully transferred from the website and
// it is ready to be shown in the cell.
//
// In case of load failure, we simply discard the NSString key/value from the cache.
//

//
//
//
@implementation FaceController

- (id) initWithOwner: (id) theOwner
{
  NSBundle *aBundle;
  
  self = [super init];

  owner = theOwner;
 
  aBundle = [NSBundle bundleForClass: [self class]];
  
  resourcePath = [aBundle resourcePath];
  RETAIN(resourcePath);

  allFaceViews = [[NSMutableArray alloc] init];

  cache = [[NSMutableDictionary alloc] init];

  return self;
}


//
//
//
- (void) dealloc
{
  NSDebugLog(@"FaceController: -dealloc");

  RELEASE(resourcePath);
  RELEASE(allFaceViews);
  
  RELEASE(cache);

  [super dealloc];
}



//
//
//
+ (id) singleInstance
{
  NSDebugLog(@"FaceController: -singleInstance");

  if (!singleInstance)
    {
      singleInstance = [[FaceController alloc] initWithOwner: nil];
    }
  
  return singleInstance;
}


//
// access / mutation methods
//
- (NSString *) name
{
  return @"Face";
}

- (NSString *) description
{
  return @"This is a simple Face bundle supporting X-Face and X-Image-URL.";
}

- (NSString *) version
{
  return @"v0.3.0";
}

- (void) setOwner: (id) theOwner
{
  owner = theOwner;
}

//
// UI elements
//
- (BOOL) hasPreferencesPanel
{
  return NO;
}

- (BOOL) hasComposeViewAccessory
{
  return NO;
}

- (BOOL) hasViewingViewAccessory
{
  return YES;
}


//
//
//
- (id) viewingViewAccessory
{  
  Face *aFace;

  aFace = [[Face alloc] initWithResourcePath: resourcePath];

  [allFaceViews addObject: aFace];

  return AUTORELEASE(aFace);
}


//
//
//
- (enum ViewingViewType) viewingViewAccessoryType
{
  return ViewingViewTypeHeaderCell;
}


//
//
//
- (void) viewingViewAccessoryWillBeRemovedFromSuperview: (id) theView
{
  if (!theView)
    {
      return;
    }
  else
    {
      Face *aFace;
      int i;
      
      for (i = 0; i < [allFaceViews count]; i++)
	{
	  aFace = [allFaceViews objectAtIndex: i];
	  
	  if ( [theView containsView: aFace] )
	    {
	      [allFaceViews removeObject: aFace];
	      break;
	    }
	}
    }
}


//
//
//
- (void) setCurrentSuperview: (NSView *) theView
{
  superview = theView;
}


//
//
//
- (NSArray *) submenuForMenu: (NSMenu *) theMenu
{
  return nil;
}


//
//
//
- (NSArray *) menuItemsForMenu: (NSMenu *) theMenu
{
  return nil;
}


- (Face *) faceFromTextView: (id) theTextView
{
  Face *aFace;
  int i;

  aFace = nil;

  // First, we find the face associated to the textview
  for (i = 0; i < [allFaceViews count]; i++)
    { 
      aFace = [allFaceViews objectAtIndex: i];
      
      // Warning: the textview's delegate MUST be the windowController so
      //          the Face is correctly displayed.
      if ([[[theTextView delegate] mailHeaderCell] containsView: aFace])
	{
	  break;
	}
    }

  return aFace;
}


//
// Pantomime related methods
//
- (void) messageWillBeDisplayed: (CWMessage *) theMessage
			 inView: (NSTextView *) theTextView
{
  NSEnumerator *theEnumerator;
  NSString *aKey;
  Face *aFace;
  
  BOOL hasFoundHeader;

  hasFoundHeader = NO;
  aFace = [self faceFromTextView: theTextView];
  
  if (!aFace) return;

  // We verify if our header is present.
  theEnumerator = [[theMessage allHeaders] keyEnumerator];
  
  while ((aKey = [theEnumerator nextObject]))
    {
      if ([aKey caseInsensitiveCompare: @"X-Image-URL"] == NSOrderedSame ||
	  [aKey caseInsensitiveCompare: @"X-Face"] == NSOrderedSame)
	{
	  hasFoundHeader = YES;
	  break;
	}
    }
  
  
  
  if (hasFoundHeader)
    {
      NSString *aString;
      
      aString = [theMessage headerValueForName: aKey];
      
      // We search for X-Image-URL / X-Face
      if (aString)
	{
	  id o;
	  
	  // We verify if the image is in our cache. If not, we create it and add it to our cache.
	  o = [cache objectForKey: aString];
	  
	  if (!o)
	    {
	      // If it's an X-URL-Image
	      if ([aKey caseInsensitiveCompare: @"X-Image-URL"] == NSOrderedSame)
		{
		  NSURLHandle *aHandle;
		  NSURL *aURL;
		  
		  aURL = [NSURL URLWithString: aString];
		  aHandle = [aURL URLHandleUsingCache: NO];
		  [aHandle addClient: self];
		  [aHandle loadInBackground];
		  
		  o = [[NSArray alloc] initWithObjects: aURL, aHandle, nil];
		}
	      else
		{
		  o = [[NSImage alloc] initWithXFaceString: aString];
		}
	      
	      if (o)
		{
		  [cache setObject: o  forKey: aString];
		  RELEASE(o);
		}
	    }
	  
	  if ([o isKindOfClass: [NSArray class]])
	    {
	      [aFace setImage: nil];
	    }
	  else
	    {
	      [aFace setImage: o];
	    }
	}
    }
  else
    {
      [aFace setImage: nil];
    }
  
  [aFace setNeedsDisplay: YES];
}


//
//
//
- (NSString *) XImageURLFromHandle: (NSURLHandle *) theHandle
{
  NSArray *allKeys;
  NSString *aKey;
  id o;
  
  int i, count;
  
  allKeys = [cache allKeys];
  count = [allKeys count];

  for (i = 0; i < count; i++)
    {
      aKey = [allKeys objectAtIndex: i];
      o = [cache objectForKey: aKey];

      if ([o isKindOfClass: [NSArray class]])
	{
	  if ([o lastObject] == theHandle) return aKey;
	}
    }

  return nil;
}


//
//
//
- (void) URLHandleResourceDidBeginLoading: (NSURLHandle *) sender
{
  // We do nothing here for now
}


- (void) URLHandleResourceDidCancelLoading: (NSURLHandle *) sender
{
  // We do nothing here for now
}

- (void)              URLHandle: (NSURLHandle *) sender
 resourceDataDidBecomeAvailable: (NSData *) newBytes
{
  // We do nothing here for now
}


- (void)                URLHandle: (NSURLHandle *) sender
 resourceDidFailLoadingWithReason: (NSString *) reason
{
  // We remove the cache entry
  [cache removeObjectForKey: [self XImageURLFromHandle: sender]];
}

- (void) URLHandleResourceDidFinishLoading: (NSURLHandle *) sender
{
  NSString *aKey;
  NSData *aData;

  aKey = [self XImageURLFromHandle: sender];
  aData = [sender resourceData];

  if (!aData)
    {
      [cache removeObjectForKey: aKey];
    }
  else
    {
      NSArray *allWindows;
      CWMessage *aMessage;
      NSImage *aImage;
      Face *aFace;
      
      id aController;
      int i, count;

      aImage = [[NSImage alloc] initWithData: aData];

      if (!aImage)
	{
	  [cache removeObjectForKey: aKey];
	  return;
	}

      [cache setObject: aImage
	     forKey: aKey];
      RELEASE(aImage);

      // We now check if we must refresh our MailHeaderCells!
      allWindows = [GNUMail allMailWindows];
      count = [allWindows count];
      
      for (i = 0; i < count; i++)
	{
	  aController = [[allWindows objectAtIndex: i] windowController];
	  aMessage = [aController selectedMessage];
	  
	  if ([[aMessage headerValueForName: @"X-Image-URL"] isEqualToString: aKey])
	    {
	      // We now find which Face is associated with that specific textView.
	      aFace = [self faceFromTextView: [aController textView]];
	      [aFace setImage: aImage];
	      [[aController textView] setNeedsDisplay: YES];
	    }
	}
    }
}

@end
