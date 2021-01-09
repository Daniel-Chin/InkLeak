# Ink Leak
A React.js component that animates text as a canvas.  

## Problem
I have an error that I can't fix. "Support for the experimental syntax 'jsx' isn't currently enabled"  

So I can't use npm to package it. Now I can only use it by copying the code into the component folder.  

## Usage
```jsx
import InkLeak from 'inkleak';

<InkLeak text='a quick brown fox' height={100} />
```

## Font Tracing Tool
"vectorize" a fontface.  
Video tutorial: https://youtu.be/P0wlk5VokOg  
Left click: add point.  
"c": **c**lose loop.  
"s": new **s**troke.  
"w": set **w**idth and preview.  
"W": save **W**idth and advance to next letter.  
Right click: Undo.  
