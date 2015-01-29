<h1>Processing-browser</h1>

<h3> A simplified 'web browser' which parses and displays a reduced
 HTML language.</h3>

<p>This was written in Spring '14 as my final project for a Programming Languages: Design and Implementation course, with the intent of showing off some of the features Processing adds to Java. It is not intended for use outside of that.</p>
 


<h3>Tag Descriptions</h3>
 
 <p>Text tags may use the following attributes:
 font-family
 font-size
 color
 background color</p>
 
<p>Block tags may use the following attributes:
 width
 height
 left
 right
 padding
 font-family
 font-size
 color
 background color
 border</p>
 
<p>Block-text tags may use the following attributes:
 font-family
 font-size
 color
 background color
 border(size, color)</p>
 
<p>Inline tags may use the following attributes:
 font-weight
 font-size
 font-family
 text-style
 text-decoration
 color
 background color</p>
 
 a - link;
 tag type - text;
 attributes:
 ref - filepath to new document, required
 
 br - line breaks;
 tag type - text
 attributes:
 none
 
 div - general block elements;
 tag type - block
 attributes:
 none
 
 em - inline style elements, italic by default;
 tag type - inline
 attributes:
 none

 hr;
 tag type - block
 attributes:
 none
 
 h1-h6 - bold, larger size headers;
 tag type - block-text
 attributes:
 none 
 
 img - images;
 tag type - block
 attributes:
 source - filepath to image source, required 
 
 li - list items;
 tag type - block
 attributes:
 none
 
 p - paragraphs;
 tag type - block-text
 attributes:
 none 
 
 span - inline style tag, no default values;
 tag type - inline
 attributes:
 none
 
 strong - inline style tag, bold by default;
 tag type - inline
 attributes:
 none
 
 table - tables;
 tag type - block
 attributes:
 none
 
 td - table cells;
 tag type - block
 attributes:
 colspan - override default width
 
 tr - table rows;
 tag type - block
 attributes:
 none
 
 ul - lists;
 tag type - block
 attributes:
 listStyle - specify style of list marker 