/******************************************************************

 Programming Languages Term Project
 Mark Safran & Sam Silberstein
 
 A simplified 'web browser' which parses and displays a reduced
 HTML language. 
 *****************************************************************
 ***                                                           ***
 ***                   tag descriptions                        ***
 ***                                                           ***
 *****************************************************************
 
 text tags may use the following attributes:
 font-family
 font-size
 color
 background color
 
 block tags may use the following attributes:
 width
 height
 left
 right
 padding
 font-family
 font-size
 color
 background color
 border
 
 block-text tags may use the following attributes:
 font-family
 font-size
 color
 background color
 border(size, color)
 
 inline tags may use the following attributes:
 font-weight
 font-size
 font-family
 text-style
 text-decoration
 color
 background color 
 
 a - link:
 tag type: text
 attributes:
 ref: filepath to new document, required
 
 br - line breaks:
 tag type: text
 attributes:
 none
 
 div - general block elements:
 tag type: block
 attributes:
 none
 
 em - inline style elements, italic by default:
 tag type: inline
 attributes:
 none
 hr:
 tag type: block
 attributes:
 none
 
 h1-h6 - bold, larger size headers:
 tag type: block-text
 attributes:
 none 
 
 img - images:
 tag type: block
 attributes:
 source: filepath to image source, required 
 
 li - list items:
 tag type: block
 attributes:
 none
 
 p - paragraphs:
 tag type: block-text
 attributes:
 none 
 
 span - inline style tag, no default values:
 tag type: inline
 attributes:
 none
 
 strong - inline style tag, bold by default:
 tag type: inline
 attributes:
 none
 
 table - tables:
 tag type: block
 attributes:
 none
 
 td - table cells:
 tag type: block
 attributes:
 colspan: override default width
 
 tr - table rows:
 tag type: block
 attributes:
 none
 
 ul - lists:
 tag type: block
 attributes:
 listStyle: specify style of list marker 
 *******************************************************************/



/*******************************************************************
  element class
  
  All HTML elements are read from a file, and stored in the following
  data structure. The various attributes, such as type, text, height,
  etc, are all stored as key/value pairs in the JSONObject, 'data'. 
  Each element also stores several pointers to its neighboring elements.
*******************************************************************/
class element {
  JSONObject data;
  element next;
  element last;
  element children;
  element parent;

  element() {
    next = null;
    last = null;
    children = null; 
    parent = null;
    data = new JSONObject();
  }
};

JSONObject fontSize = new JSONObject(); // the default font-sizes for each HTML tag will be stored in this object
JSONObject padding = new JSONObject();  // the default padding widths for each HTML tag will be stored in this object

String address, filename;               // holds the names for the text in the address bar, and the currently displayed file

boolean newFile = true;                 // flag which signals when filename should be updated and a new file should be parsed

JSONArray links = new JSONArray();      // array which will store a copy of all of the links on the page, so that their addresses can be more easily accessed
int numLinks = 0;                       // holds the number of links on the page

PImage[] images = new PImage[100];      // array which will store all of the images on the page. image elements themselves will only store the index for this array
                                        // I put a cap on 100 because if you have 100 images on the page it probably won't even run...
int numImages = 0;                      // total number of images on the page

String[] history = new String[100];     // holds file viewed history. when a new file is loaded its name is stored in this array
                                        //100 also seems like a reasonable limit on how many pages to store in history
                                        
int currentPage = 0;                    // index in the array of the currently displayed file
int numPages = 1;                       // total number of pages visited (always starts at 1)

/*******************************************************************************************************
 several global 'elements' are stored.
 The document root, 'body', is stored globally so that it can be accessed across all functions.
 currentLast and currentParent are used in setting up the element tree structure.
 firstPlaceholder is a copy of the first 'element', just for that one place in display where I need to 
      make sure we aren't comparing something to the garbage first 'element'
*******************************************************************************************************/
element body = new element();
element currentLast = new element();
element firstPlaceholder = currentLast;
element currentParent = new element();

int lineHeight = 20;          // stores how many pixels tall a 'line' is. this variable is updated every time a new font is loaded
boolean typingActive = false; // boolean flag which determines whether or not to accept typing input in the address bar
float currentPosition = 0;    // stores values 0 - 1 which indicates what percentage down the page the user has scrolled to
boolean scrolled = false;     // boolean flag which determines when the scroll bar has been moved



void setup()
/*
  setup is called at the beginning of the program run, and does all of the tasks that do not
  require the repetitive nature of 'loop()'
 */
{
  size(600, 600);  // sets the initial window size to 600x600 pixels

  // set the frame to resizable so that the user can change the size of the window
  if (frame != null) {
    frame.setResizable(true);
  }
  
  //several initialization steps required to set up the element tree structure
  currentParent = body;
  body.data.setString("type", "body");
  body.data.setInt("id", 0);
  body.data.setInt("height", height);
  body.data.setInt("width", width);
  currentLast.data.setInt("id", 0);
  
  //sets a default value for line height, but this is overwritten almost immediately
  textLeading(10);
  
  //loads files into the fontSize and padding JSONArrays described above
  initializeDefaults();
  
  //initial file to load
  filename = "home.html";
  
  //store that name in the history array
  history[0] = filename;
}

void draw()
/*
  draw is a function that is continuously called by the Processing engine or what have you
 
  depending on whether or not the 'newFile' flag is true or false draw does one of the following:
  
  if newFile is true:
      draw reads in and stores the text from the new file, 
           creates the new element tree and stores it in the document root,
           sets newFile to false so that draw will switch to 'displaying' mode,
           stores the value of the filename in the address variable so that it will be displayed,
           calculates all of the attribute values for height, width, position, etc
           
  if newFile is false:
     draw resets the height and width of the document root,
          recalculates all of the attribute values based on this potential change,
          clears the drawing screen and resets a white background,
          draws all of the elements on the page,
          and draws the navigation and scrollbar
*/
{
  String data;
  
    if (newFile == false)
    {
      
      if (height != body.data.getInt("height") || width != body.data.getInt("width") || scrolled)
      {
        body.data.setInt("height", height);
        body.data.setInt("width", width);
  
        calculateAttributes(body.children, width - 20, 0, 50);      
        clear();
        background(255,255,255);
        display(body.children);
      }
      

      //printDOM(body.children, 0);
      //print("\n\n\n");
      //noLoop();
      drawNavigation();
      drawScroll();
      scrolled = false;
    }
    else
    {     
      body = new element();
      currentLast = new element();
      firstPlaceholder = currentLast;
      currentParent = new element();
      currentParent = body;
      body.data.setString("type", "body");
      body.data.setInt("id", 0);
      body.data.setInt("height", height);
      body.data.setInt("width", width);
      currentLast.data.setInt("id", 0);
      data = readFile(filename);
      body.children = parseHTML(data, 1); 
      newFile = false;
      address = filename;
      currentPosition = 0;
      calculateAttributes(body.children, width - 20, 0, 50);
      clear();
      background(255,255,255);
      display(body.children);
    }   
    
}

String readFile(String filename)
/*
  returns a string containing all of the file data, with whitespace stripped out
*/
{
  String filedata = "";
  String line;
  BufferedReader reader;
  
  reader = createReader(filename);
  
  try {
    line = reader.readLine();
  } 
  catch (Exception e) {
    return readFile("404.html");
  }
  filedata += line;
  
  while(line != null)
  {
     try {
      line = reader.readLine();
     } 
     catch (IOException e) {
       e.printStackTrace();
       line = null;
     }
     filedata += line;
  }
  
   // html strips out white space when it is anything more than a single space
   filedata = filedata.replaceAll("[\t\n]", "");
   filedata = filedata.replaceAll(" +", " ");
   
   return filedata;
}

element parseHTML(String filedata, int id)
/*
  parseHTML creates the element tree structure from the data in the HTML file
  This is done by recursively splitting the file data into several segments with a regular expression containing 5 sections
  
  Section 1, "[^<]": captures everything in front of a tag, which will be discarded
  Section 2, "/?[a-zA-Z1-6]+": captures the name of the tag, which will be stored in the "type" attribute of the element
  Section 3, "[^>]*": captures all of the attribute data contained in the angle brackets of the tag
  Section 4, "[^<]*": captures all of the data before the next tag, i.e. the text contained in the current tag
  Section 5, ".*": captures the rest of the file, which will be used in the recursive call to parseHTML
*/
{
  element newTag = new element();
  element temp;
  newTag.last = currentLast;
  newTag.next = null;
  newTag.children = null;

  // processing's built in match function returns the results of running a regular expression on a string
  String[] tag = match(filedata, "([^<])*<(/?[a-zA-Z1-6]+)[ \t\n\f\r]*([^>]*)>([^<]*)(.*)");
  if (tag == null)//no more tags
  {
    return null;
  }
  else if (tag[2].charAt(0) == '/')
    // if the first character of section 2 is a '/', then this is the closing tag, not the opening one.
    // any trailing text is added as an element of the same type as the parent (ie scenarios like <td>td text here <a ref="somepage.html">link text</a> more td text here </td>)
    // after that is accomplished, the element pointers are changed back to the state of the parent call to parseHTML and the function is called again on the remaining data
  {
    if (tag[4] != null && tag[4].length() > 0 && !tag[4].equals("null"))
    {
      element splitOffText = new element();
      splitOffText.parent = currentParent;
      currentLast.next = splitOffText;
      splitOffText.last = currentLast;
      
      // in order to copy the data over, but create a new JSONObject, we have to 
      // assign the new object to the result of parsing the stringified data
      splitOffText.data = JSONObject.parse(currentParent.data.toString());
      splitOffText.data.setString("text", tag[4]);
    }
    
    if (currentParent.data.getString("type").equals(tag[2].substring(1)))
    {
      currentParent = currentParent.parent;
    }
    temp = currentParent.children;

    while (temp.next != null)
    {
      temp = temp.next;
    }
    currentLast = temp;

    return parseHTML(tag[5], id + 1);//strip closing tag off, run again
  }
  else
  // at this point we've determined that a new tag has been found, but it could still be the parent's closing tag
  {
    newTag.data.setString("type", tag[2]);
    newTag.data.setInt("id", id);
    parseAttrs(newTag, tag[3]);
    newTag.data.setString("text", tag[4]);
    newTag.parent = currentParent;

    // determines where to add the current element to in the tree
    if (currentParent.children == null)
    {
      currentParent.children = newTag;
    }
    else
    {
      currentLast.next = newTag;
    }

    if (tag[5].length() > 1 && tag[5].charAt(1) != '/')//new tag
    {      
      currentParent = newTag;
      newTag.children = parseHTML(tag[5], id + 1);
      currentParent = newTag.parent;
      return newTag;
    }
    else// parent's closing tag
    {
      currentLast = newTag;
      parseHTML(tag[5], id + 1);

      currentLast = newTag.last;
      return newTag;
    }
  }
}

void parseAttrs(element newTag, String attrs)
/*
  takes the attribute data from parseHTML and splits it into attribute/value pairs, then stores all of those in the JSONObject
  
  almost all of the attributes are numerical, so the values are stored as integers by default, except for a few cases which require separate storage
*/
{
  String[] splitAttrs = split(attrs, " ");
  String[] pair;
  
  for (int i = 0; i < splitAttrs.length; i++)
  {
    pair = match(splitAttrs[i], "([a-zA-Z]+)=\"(#?[^\"]+)\"");
    if (pair != null && pair[1] != null && pair[2] != null)
    {
      if (pair[2].charAt(0) == '#')
      // colors are stored with the syntax 'color="#255,0,0"', so if the first character is a pound sign, store the color as a string, but strip off the #
      {
        newTag.data.setString(pair[1], pair[2].substring(1));
      }
      else if (pair[1].equals("ref") || (pair[1].length() > 4 && pair[1].substring(0,4).equals("font")) || pair[1].equals("listStyle") || pair[1].equals("decoration"))
      // all of these attributes are stored as strings, but none of them need any additional formatting
      {
         newTag.data.setString(pair[1], pair[2]); 
      }
      else if (pair[1].equals("source") && newTag.data.getString("type").equals("img"))
      // rather than set aside space for images in every element, we just store them in the images array created earlier
      // and store the index in the element itself
      // in the off chance that parseAttrs is called on an element that already exists, we check to see if the image exists
      // before creating it
      {
        if(newTag.data.getInt("imgID", -1) == -1)
        {
          PImage newImage = loadImage(pair[2]);
          newTag.data.setInt("imgID", numImages);
          images[numImages++] = newImage; 
        } 
      }
      else
      // general case, store value as a number
      {
        newTag.data.setInt(pair[1], Integer.parseInt(pair[2]));
      }
    }
  }
}

void printDOM(element head, int depth)
/*
  i just used DOM to sound cool and because I didn't want to think of another word for document object structure, i know there isn't actually a DOM
  
  this function was only used for debugging, and it prints out the width, height, left and top positions of each element, and indents them to show tree structure
 */
{
  for (int i = 0; i < depth; i++)
  {
    print("\t");
  }
  
  print(head.data.getString("type"));
  print( " width: " + head.data.getInt("width") + " height: " + head.data.getInt("height") 
    + " left: " + head.data.getInt("left") + " top: " +head.data.getInt("top"));

  if (head.children != null)
  {
    print("\n");
    printDOM(head.children, depth + 1);
  }

  if (head.next != null)
  {
    print("\n");
    printDOM(head.next, depth);
  }
}

float calculateAttributes(element newTag, int eleWidth, int left, int top)
/*
  will calculate values for position, width, height, background, etc based on parents and children
  
  returns a float containing the calculated height of the element it is given as a parameter
  
  other parameters are the values calculated for width, left, and top by the element's parent
  
  this function is really such a mess at this point, but I'll do my best to explain it.
*/
{
  int eleHeight;
  
  // totalHeight is used to keep track of the height of the elements which come after this one
  // so that the combination of that and this element's height can be returned to the parent element
  float totalHeight = 0;
  
  // first, there are several attributes (width, left, top, and background) that are determined by either the HTML file itself, or the tag's parent, so we can 
  // set those right away.  
  newTag.data.setInt("width", newTag.data.getInt("setWidth",eleWidth));
  newTag.data.setInt("left", newTag.data.getInt("setLeft", left));
  newTag.data.setInt("top", newTag.data.getInt("setTop", top));
  newTag.data.setString("background", newTag.data.getString("background", newTag.parent.data.getString("background", "255,255,255")));
  
  // this value determines whether or not the position is hard-coded in the html file, and if it is
  // this element's height is ignored when calculating its parent's height, and its neighbors 
  // vertical position
  boolean outOfPlace = (newTag.data.getInt("left") != left) || (newTag.data.getInt("top") != top);
  
  
  // unfortunately, we need to set the fontWeight, the default of which is bold, for header elements here, 
  // because it will be used to calculate the textWidth in a moment. 
  if (isHeader(newTag))
  {
     newTag.data.setString("fontWeight", newTag.data.getString("fontWeight", "bold")); 
  }
  
  // loads the font values for this tag, so that textWidth is accurately calculated
  setFont(newTag);
  
  // eleHeight is gradually calculated throughout this function, and is initialized as the width in pixels of the
  // text contained in the element
  eleHeight = (int)textWidth(newTag.data.getString("text", ""));

  
  // however, that is a meaningless value for eleHeight to have, and it is only stored above to facillitate converting
  // text width into number of lines and then pixel height
  // list items have a separate calculation, because some space is stripped off from their sides to make room for
  // bullet points
  if (newTag.data.getString("type").equals("li"))
  { 
    eleHeight = (eleHeight == 0) ? 0 : lineHeight * ((eleHeight / (eleWidth - 15)) + 1);
  }
  else
  {
    eleHeight = (eleHeight == 0) ? 0 : lineHeight * ((eleHeight / eleWidth) + 1);
  }
  
  // if there is a setHeight value for the element, the previously calculated height is overridden
  eleHeight = newTag.data.getInt("setHeight", eleHeight);
  newTag.data.setInt("height", eleHeight);
  
  // to simplify repeatedly calculating various values for child attributes, they are computed here and used below
  // the size of the border and padding in the element is added/subtracted from parent attributes to ensure child attributes are appropriately positioned
  int childWidth = newTag.data.getInt("width"), childHeight = newTag.data.getInt("height", eleHeight), childLeft = newTag.data.getInt("left"), childTop = newTag.data.getInt("top");
      childWidth -= newTag.data.getInt("bordersize", 0) * 2;
      childWidth -= newTag.data.getInt("padding", padding.getInt(newTag.data.getString("type"))) * 2;
      childLeft += newTag.data.getInt("bordersize", 0);
      childLeft += newTag.data.getInt("padding", padding.getInt(newTag.data.getString("type")));
      childTop += newTag.data.getInt("bordersize", 0);
      childTop += newTag.data.getInt("padding", padding.getInt(newTag.data.getString("type")));
      
      
      
  // most of the different element types are treated the same for the purposes of calculating the attributes of their children,
  // but the following if ... else if .. else takes care of the types that have specific differences
  
  
  if (newTag.data.getString("type").equals("table"))
  // before width can be calculated for table cells, the number of cells in a row must be computed.
  // it ended up being necessary to store this in the table element, so that it can be accessed
  // by all of the table rows.
  {   
    newTag.data.setInt("numcols", countCols(newTag)); // countCols returns the integer value of cells per row
    if (newTag.children != null)
    {
      eleHeight += calculateAttributes(newTag.children, childWidth, childLeft, childTop + eleHeight);
      eleHeight += newTag.data.getInt("padding", padding.getInt(newTag.data.getString("type"))) * 2;
    }
  }
  else if (newTag.data.getString("type").equals("tr"))
  // table rows require the additional calculation of dividing their overall width by the number of columns in their parent, the table
  {
    if (newTag.children != null)
    {
      eleHeight += calculateAttributes(newTag.children, childWidth / newTag.parent.data.getInt("numcols"), childLeft, childTop + eleHeight);
      eleHeight += newTag.data.getInt("padding", padding.getInt(newTag.data.getString("type"))) * 2;
    }
  }
  else if (newTag.data.getString("type").equals("img"))
  // the width and height of an image don't depend on its parents or children (because it may not have children), so whatever size and width
  // were previously calculated are ignored and replaced by the height and width stored in the image data itself.
  // it was necessary to put this clause here so that images could be prevented from having children 
  {
     newTag.data.setInt("width", images[newTag.data.getInt("imgID")].width + newTag.data.getInt("padding", padding.getInt(newTag.data.getString("type"))) * 2);
     newTag.data.setInt("height", images[newTag.data.getInt("imgID")].height + newTag.data.getInt("padding", padding.getInt(newTag.data.getString("type"))) * 2);
     eleWidth = newTag.data.getInt("width");
     eleHeight = newTag.data.getInt("height");
  }
  else if (newTag.data.getString("type").equals("br"))
  // line breaks fall into a similar category in that they are not allowed to have children. Furthermore, they may not have text,
  // and their height is necessarily the same as one line
  {
     newTag.data.setString("text", "");
     newTag.data.setInt("height", lineHeight);
     eleHeight = lineHeight;
  }
  else 
  // all other tags fall into this category
  {      
    if (isInline(newTag))
    // i had to put this structure, which sets the default values for the different inline tags, somewhere, and here
    // seemed like just as good a place as any.
    {
     if (newTag.data.getString("type").equals("a"))
     {
        newTag.data.setString("color", newTag.data.getString("color", "0,0,255"));
        newTag.data.setString("decoration", newTag.data.getString("decoration", "underline"));
     } 
     else if (newTag.data.getString("type").equals("strong"))
     {
        newTag.data.setString("fontWeight", newTag.data.getString("fontWeight", "bold")); 
     }
     else if (newTag.data.getString("type").equals("em"))
     {
        newTag.data.setString("fontStyle", newTag.data.getString("fontStyle", "italic")); 
     }
    
    
     // children of inline elements are calculated slightly differently that normal elements
     // inline elements ignore all but one line of their height
     if (newTag.children != null)
     {
       calculateAttributes(newTag.children, childWidth, childLeft, newTag.data.getInt("top") + lineHeight);
       eleHeight += newTag.data.getInt("padding", padding.getInt(newTag.data.getString("type"))) * 2;
     } 
    }
    else if (newTag.children != null)
    // finally, the base case in which all the other elements call calculateAttributes on their children
    // the height returned by this function call is added to the height which will be stored in the element
    {
      eleHeight += calculateAttributes(newTag.children, childWidth, childLeft, childTop + eleHeight);
      eleHeight += newTag.data.getInt("padding", padding.getInt(newTag.data.getString("type"))) * 2;
    }
  }
  
  // set the height again, to accommodate for children's height
  newTag.data.setInt("height", eleHeight);
  
  // now that the element has determined its height, it calls calculateAttributes on any elements that 
  // come below it (next) in the tree structure, using its value for height in the calculation for the
  // next element's vertical position
  if (newTag.next != null)
  {
    if (newTag.data.getString("type").equals("td"))
    // table cells have a different calculation than other elements, since their neighbors appear
    // after them horizontally, rather than vertically. Therefore, it is the left position that
    // is increased, not the top position.
    {
      int cellWidth = newTag.data.getInt("colspan", 1) * newTag.data.getInt("width");//colspan can specify how many cell widths a cell should take up
      newTag.data.setInt("width", cellWidth);
      totalHeight = calculateAttributes(newTag.next, eleWidth, left + cellWidth, top);
      
      // the height of a table row is constant across it, so whichever table cell has the largest height should be the one to
      // return its value
      if (totalHeight < eleHeight)
      {          
        totalHeight = (float)eleHeight;
      }  
      newTag.data.setInt("height", eleHeight);
      return totalHeight;
    }  
    else
    {  
      // this prevents elements which have a preset height from affecting the vertical position
      // of the elements that follow it
      if (newTag.data.getInt("top") == top)
      {
        top += eleHeight;
      }
      
      totalHeight += calculateAttributes(newTag.next, eleWidth, left, top + newTag.data.getInt("bordersize", 0) * 2);
    }
  }
  
  // increase the total height to accommodate for borders
  totalHeight += newTag.data.getInt("bordersize", 0) * 2;
  
  if(newTag.data.getString("type").equals("a"))
  // for all link elements, store all of the data in the links array
  // so that the ref and position may be referenced later
  {
    links.setJSONObject(numLinks++, JSONObject.parse(newTag.data.toString()));
  }
  
  // used to prevent statically positioned elements from affecting
  // the height of their parents
  if(outOfPlace)
  {
     return 0; 
  }
  
  return eleHeight + totalHeight;
}

int countCols(element table)
/*
  returns the integer amount of columns in table rows
*/  
{
  int columns = 0;
  int tempcol = 0;
  element temp = table.children;
  element row;
  if (table.children != null)
  {
    while (temp != null)//loops through all rows, saving the largest column count
    {
      if (temp.children != null)
      {
        row = temp.children;
        while (row != null)//this loop counts columns in an individual row
        {
          tempcol += row.data.getInt("colspan", 1);
          row = row.next;
        }
      }

      if (tempcol > columns)
      {
        columns = tempcol;
      }
      tempcol = 0;
      temp = temp.next;
    }
  }
  return columns;
}

void initializeDefaults()
/*
  loads the JSON files which contain default values for fontSize and padding
 */
{
  fontSize = loadJSONObject("defaults/fontSize.json");
  padding = loadJSONObject("defaults/padding.json");
}

void display(element tag)
/*
  handles actually drawing all of the elements on the screen
  
  this basically comes down to drawing a colored rectangle, and writing the text
 */
{
  String[] RGBvals; // used to split up the color string into red, green, and blue values
  String type = tag.data.getString("type"); // the type tag is used a lot in this function, so I made a separate variable to hold it
  int left, top, eleWidth, eleHeight; // same goes for these values

  // copy over the positioning values
  left = tag.data.getInt("left", 0);
  top = tag.data.getInt("top", 0);
  eleWidth = tag.data.getInt("width", 0);
  eleHeight = tag.data.getInt("height", 0);
  
  if (type.equals("li"))
  // list items are one of the few cases that act differently
  // the text/background rectangle are pushed to the right so that the list item marker can be drawn on the left
  // the default marker is a circle, other options are square and triangle.
  // if any value aside from these is used, no marker is drawn and left, eleWidth are set back to normal
  {
     left += 16;
     eleWidth -= 16; 
     
     String listStyle = tag.parent.data.getString("listStyle", "circle");
     if (listStyle.equals("circle"))
     {
        fill(0,0,0);
        ellipse(left - 8, top + (lineHeight * .5), 6, 6);
     }
     else if (listStyle.equals("square"))
     {
        fill(0,0,0);
        rect(left - 11, top + (lineHeight * .2), 6, 6);
     }
     else if (listStyle.equals("triangle"))
     {
        fill(0,0,0);
        triangle(left - 11, top + (lineHeight * .2), left - 5, top + (lineHeight * .5), left - 11, top + (lineHeight * .8));       
     }
     else 
     {
        left -= 16;
        eleWidth += 16; 
     }
  }

  // split the color string on commas, convert the values from strings to integers, and set this as the drawing color
  // if no background color is set, use the parent's background color. if that is not set, default to white
  RGBvals = split(tag.data.getString("background", tag.parent.data.getString("background", "255,255,255")), ',');
  fill(Integer.parseInt(RGBvals[0]), Integer.parseInt(RGBvals[1]), Integer.parseInt(RGBvals[2]));

  // a bordersize can be set for any element.
  // if the size is anything greater than zero the border is drawn,
  // otherwise noStroke is called to prevent a border from being drawn
  if (tag.data.getInt("bordersize", 0) > 0)
  {
    strokeWeight(tag.data.getInt("bordersize"));
    stroke(tag.data.getInt("bordercolor", #000000));
  }
  else
  {
    noStroke();
  }
  
  // draw the background rectangle, accounting for vertical scrolling
  // by subtracting currentPosition * bodyHeight from the top value
  rect(left + tag.data.getInt("bordersize", 0) / 2, 
       top + tag.data.getInt("bordersize", 0) / 2, 
       eleWidth - tag.data.getInt("bordersize", 0), 
       eleHeight + tag.data.getInt("bordersize", 0) - (int)(currentPosition * getBodyHeight()));

  if (tag.data.getString("type").equals("img"))
  // images are not allowed to have text, instead draw the image stored at imgID in the images array
  {
    image(images[tag.data.getInt("imgID")], left, top - (int)(currentPosition * getBodyHeight()));
  }
  else
  // general case
  {
    setFont(tag);    // set the values for font, fontsize, etc
    
    // again, split the color, which defaults to the parent's color, or black
    RGBvals = split(tag.data.getString("color", tag.parent.data.getString("color", "0,0,0")), ',');
    fill(Integer.parseInt(RGBvals[0]), Integer.parseInt(RGBvals[1]), Integer.parseInt(RGBvals[2]));
    
    // also set the stroke color, which will be used if the text is underlined
    stroke(Integer.parseInt(RGBvals[0]), Integer.parseInt(RGBvals[1]), Integer.parseInt(RGBvals[2]));
    
    if(isInline(tag))
    // inline tags must account for the fact that they could be drawn on the same line as their parent tag,
    // so the parent's text's end position is used in the call to write text
    // it also stores its own lastCursor value, so that any tag that might come directly after it can properly position itself
    {
       setFont(tag.parent);
       JSONObject position = textPosition(tag.parent.data.getString("text"), left, top, eleWidth);
       setFont(tag);
       int lastCursor = writeText(tag, left, left + eleWidth, top  + (int)(lineHeight * .9) - (int)(currentPosition * getBodyHeight()), position.getInt("left"));
       tag.data.setInt("lastCursor", lastCursor);
    }
    else if (tag.last != firstPlaceholder && isInline(tag.last))
    // as mentioned above, tags that come just after inline tags must also be drawn on the same line,
    // so they send the previous tag's lastCursor as another parameter to writeText
    {
       writeText(tag, left, left + eleWidth, top + (int)(lineHeight * .9) - (int)(currentPosition * getBodyHeight()), tag.last.data.getInt("lastCursor"));
    }
    else
    // general case, write text as normal
    {
      writeText(tag, left, left + eleWidth, top + (int)(lineHeight * .9) - (int)(currentPosition * getBodyHeight()), left);
    }
  }

  // once all of the displaying is done, call display on any child elements, or elements
  // coming after the current one
  if (tag.children != null)
  {
    display(tag.children);
  }

  if (tag.next != null)
  {
    display(tag.next);
  }
}

void mouseClicked()
/*
  processes mouseclicks to check for things like text-box activation, link clicks, etc
*/
{
  element clickedTag = new element(); // stores the link element if that is returned, otherwise not used
  String area = pointClicked(mouseX, mouseY, clickedTag); 
  
  if(area.equals("link"))
  // if a link is clicked, load the file stored in its 'ref' attribute
  {
    loadFile(clickedTag.data.getString("ref", filename)); // in the case that nothing is stored in 'ref' just load the current file
    typingActive = false;
  }
  else if(area.equals("address"))
  // if the address bar is clicked on, allow typing input
  {
     typingActive = true; 
  }
  else if(area.equals("go"))
  // load the file currently stored in 'address'
  {
    filename = address;
    newFile = true;
    typingActive = false;
    currentPage++;
    history[currentPage] = address;
    numPages = currentPage + 1;
  }
  else if(area.equals("back"))
  // go back one page, only allowed if we aren't on the first page
  {
     if (currentPage > 0)
     {
       filename = history[--currentPage];
       newFile = true; 
     }
  }
  else if(area.equals("forward"))
  // go forward one page in the history, only allowed if we aren't on the last page
  {
    if(currentPage < numPages - 1)
    {
      filename = history[++currentPage];
      newFile = true; 
    } 
  }
  else if(area.equals("up"))
  // scroll up, but reset currentPosition to 0 if it is less than that
  {
    currentPosition = currentPosition - ((float)5 / (height - 90));
    currentPosition = (currentPosition < 0) ? 0 : currentPosition;
  }
  else if(area.equals("down"))
  // scroll down, but reset currentPosition to 1 if it is more than that
  {
     currentPosition = currentPosition + ((float)5 / (height - 90));
     currentPosition = (currentPosition > 1) ? 1 : currentPosition; 
  }
  else
  // if nothing of value was clicked on, make sure typing is not active
  {
    typingActive = false;  
  }
}

void mouseDragged()
/*
  used to simulate dragging the scrollbar up and down
  currentPosition has a value 0 - 1 indicating percentage of the
  page that has been scrolled.
  
  mouseY is the value of the current vertical mouse position, pmouseY is that
  value from the last frame. the difference between those is scaled down and
  added to currentPosition
*/
{
   float bodyHeight = getBodyHeight();
   
   // don't do anything unless you've clicked inside the scroll area
   if (bodyHeight > height && boxContains(mouseX, mouseY, //x, y
       width - 20, width, //left, right
       70, height - 20)) //top, bottom
   {
     currentPosition = currentPosition + ((float)(mouseY - pmouseY) / (height - 90));
     currentPosition = (currentPosition > 1) ? 1 : ((currentPosition < 0) ? 0 : currentPosition);
     scrolled = true;
   }
}

void keyTyped()
/*
  handles keyboard input
  
  if typing is not active, nothing happens
  otherwise stores new characters in the 'address' string,
  removes characters when a backspace is entered,
  goes to a new file when enter is pressed
*/
{
  if (typingActive)
  {
    if (key == BACKSPACE)
    {
       if (address.length() > 0)
       {
         address = address.substring(0, address.length() - 1);
       }
    }
    else if (key == ENTER)
    {
      filename = address;
      newFile = true;
      typingActive = false;
      currentPage++;
      history[currentPage] = address;
      numPages = currentPage + 1;
    }
    else
    {
       address += key; 
    }
  }
}

String pointClicked(int x, int y, element returnTag)
/*
  Determines what, if anything, exists at a clicked point
*/
{
   // loop through the array of links, and check the mouse position against each of them
   // if a match is found, return link, and store the link data in the returnTag element
   for (int i = 0; i < numLinks; i++)
   {
      if(boxContains(x, y, links.getJSONObject(i).getInt("left"), 
                     (links.getJSONObject(i).getInt("left") + links.getJSONObject(i).getInt("width")), 
                     links.getJSONObject(i).getInt("top"), 
                     (links.getJSONObject(i).getInt("top") + links.getJSONObject(i).getInt("height"))))
      {
        returnTag.data = links.getJSONObject(i);
        return "link";
      }
   }
   
   // check vs the coordinates of the address bar
   if(boxContains(x, y, 90, width - 150, 10, 40))
   {
      return "address"; 
   }
   
   // go button
   if(boxContains(x, y, width - 50, width - 10, 10, 40))
   {
      return "go"; 
   }
   
   // 'back' arrow on the left of the navigation
   if(boxContains(x, y, 20, 40, 15, 35))
   {
      return "back"; 
   }
   
   // 'forward' arrow in the navigation
   if(boxContains(x, y, 50, 70, 15, 35))
   {
      return "forward"; 
   }
   
   // 'up' scroll arrow
   if(boxContains(x, y, width - 20, width, 50, 70))
   {
      return "up"; 
   }
   
   // 'down' scroll arrow
   if(boxContains(x, y, width - 20, width, height - 20, height))
   {
      return "down"; 
   }
   
   // if nothing is found, return an empty string
   return ""; 
}

boolean boxContains(int x, int y, int left, int right, int top, int bottom)
/*
  checks whether or not a given point falls inside a rectangle on the screen
*/
{
  boolean outcome = false;
  
  if((x >= left) && (x <= right) && (y <= bottom) && (y >= top))
  {
     outcome = true; 
  }
  
  return outcome;
}

void loadFile(String name)
/*
  changes the file which will be drawn on the screen
*/
{
  filename = name;
  newFile = true;
  currentPage++;
  history[currentPage] = name;
  numPages = currentPage + 1;
}

JSONObject textPosition(String text, int boxLeft, int boxTop,  int boxWidth)
/*
  calculates the position at which the last word of a string of text ends, based
  upon the size of the box containing the text
*/
{
  String lineText = "";
  JSONObject position = new JSONObject();
  int lines = (int)textWidth(text) / boxWidth; // truncate textWidth / boxWidth to get integer value of text lines
  
  // the left position is therefore the textWidth - the size of the full lines
  position.setInt("left", boxLeft + ((int)textWidth(text)  - ( boxWidth * lines)));
  
  // top is just the top of the box + the height of each line
  position.setInt("top", boxTop + lineHeight * lines);
  return position;
}

JSONObject splitText(String text, int lineWidth)
/*
  splits text into what fits on the provided line width and what does not
*/
{ 
  String remainingText = text;
  text = "";
  int charIndex;
  JSONObject textOb = new JSONObject();
  
  // while the width of the text is less than the width of the line,
  // add another word to the text by separating remainingText at the first
  // instance of ' '
  while(textWidth(text) < lineWidth && remainingText.length() > 0)
  {
     charIndex = remainingText.indexOf(" ");
     charIndex = (charIndex == -1) ? remainingText.length() - 1 : charIndex;
     
     // if adding the new word will push the text width over the line width, 
     // break out of the loop and do not change text or remainingText
     if(textWidth(text + remainingText.substring(0, charIndex + 1)) > lineWidth)
     {
       break;
     }
     text += remainingText.substring(0, charIndex + 1);
     remainingText = remainingText.substring(charIndex + 1);
  } 
  
  textOb.setString("remaining", remainingText);
  textOb.setString("text", text);
  return textOb;
}

boolean isInline(element tag)
/*
  basically just a wrapper for the if statement below, I made this function to save characters elsewhere
*/  
{
  String type = tag.data.getString("type");
  if ((type.equals("a") || type.equals("strong") || type.equals("em") || type.equals("span")))
  {
    return true;
  }
  return false;
}

int writeText(element tag, int left, int right, int top, int lineLeft)
/*
  writes the text of an element by continually splitting a line off from the total text
  and printing it to the screen
  
  the integer returned is the horizontal cursor position after all of the text has been drawn
*/
{
  String decoration = tag.data.getString("decoration", "none"); // contains 'underline' or 'none'
  String lineText, remainingText = tag.data.getString("text"); // stores the full text in remainingText so that lines can be split off from there
  JSONObject text;
  int lastCursor = 0;
  
  if (tag.data.getString("text").length() < 1)
  // if there is not text, do not print anything,
  // and return the original left value for the lastCursor value
  {
     return left; 
  }
  
  if (left != lineLeft)
  // this is the case when either the element itself is inLine
  // or the previous element was inLine
  {
     // subtract a line from top, because the new text
     // is on the same line as the old
     top -= lineHeight; 
     
     // get the first line of text, then draw it with any potential underline
     text = splitText(tag.data.getString("text", ""), right - lineLeft); 
     lineText = text.getString("text", "");
     remainingText = text.getString("remaining", "");
     text(lineText, lineLeft, top);
     if (decoration.equals("underline"))
     {
        line(lineLeft, top + 2, left + textWidth(lineText) - 1, top + 2); 
     }
    
     lastCursor = left + (int)textWidth(lineText);
     top += lineHeight;
  }
  
  // priming 'read' for the loop
  
  text = splitText(remainingText, right - left);
  lineText = text.getString("text", "");
  remainingText = text.getString("remaining", "");
  while (!lineText.equals(""))
  {
      text(lineText, left, top);
      if (decoration.equals("underline"))
      {
         line(left, top + 2, left + textWidth(lineText) - 1, top + 2); 
      }
      
      lastCursor = left + (int)textWidth(lineText);
      top += lineHeight;
      text = splitText(remainingText, right - left);
      lineText = text.getString("text", "");
      remainingText = text.getString("remaining", "");
  }
  return lastCursor;
}

void setFont(element tag)
/*
  in order for textWidth to be accurately calculated throughout the program, and for text to be drawn with the appropriate font
  several built-in functions must be called to load the font and its associated values
*/
{
  PFont font;
  font = loadFont("data/" + tag.data.getString("fontFamily", "arial").toLowerCase() + tag.data.getString("fontWeight", "").toLowerCase() + tag.data.getString("fontStyle", "") + ".vlw");
  textFont(font);
  textSize(tag.data.getInt("fontSize", fontSize.getInt(tag.data.getString("type"))));
  lineHeight = (int)(textAscent() + textDescent());
}

boolean isHeader(element tag)
/*
  similar to the isInline function before, but checks if the element is h1,h2,h3,h4,h5,h6
*/
{
   String[] type = match(tag.data.getString("type"), "^h[1-6]$");
   return (type != null); 
}

void drawNavigation()
/*
  draws the navigation bar at the top of the screen which includes:
    back and forward arrows
    address bar
    'Go!' button
*/
{
  PFont font;
  font = loadFont("data/arial.vlw");
  textFont(font);
  textSize(14);
  
  noStroke();
  fill(100,100,255);
  rect(0,0,width,50); 
  
  stroke(50,50,127);
  fill(255,255,255);
  triangle(20, 25, 40, 15, 40, 35);
  triangle(50, 15, 50, 35, 70, 25);
  
  rect(90, 10, width - 150, 30); 
  
  fill(50, 50, 127);
  rect(width - 50, 10, 40, 30, 10);
  
  fill(255,255,255);
  text("Go!", width - 40, 30);
  
  fill(0,0,0);
  text(address, 92, 30); 
  
  if (typingActive && second() % 2 == 0)
  // only draw the cursor if typing is active
  // the second() % 2 is used so that the cursor will blink
  {
     text("|", 92 + (int)textWidth(address), 30); 
  }
}

void drawScroll()
/*
  draws the scroll bar on the right hand side
*/
{
  noStroke();
  fill(230,230,230);
  rect(width - 20, 51, 20, height - 50); 
  
  fill(200);
  rect(width - 20, 50, 20, 20);
  rect(width - 20, height - 20, 20, 20);
  
  stroke(0);
  strokeWeight(2);
  line(width - 18, 67, width - 10, 53);
  line(width - 2, 67, width - 10, 53);
  
  line(width - 18, height - 18, width - 10, height - 2);
  line(width - 10, height - 2, width - 2, height - 18);
  
  int bodyHeight = getBodyHeight();
  if (bodyHeight > height)
  {
     noStroke();
     fill(100,100,255);
     
     // this random nonsense calculates how tall the scroll bar should be based on the ratio
     // between window height and body (document) height
     rect(width - 20, 70 + currentPosition * ((height - 90)-((float)(height - 90) * ((float)height / (float)bodyHeight))), 20, ((float)(height - 90) * ((float)height / (float)bodyHeight)));
  }
}

int getBodyHeight()
/*
  returns the height of the document by navigating to the last element in the top level of the tree
  and adding its height to its vertical position
*/
{
   element tag = body.children;
   int maxHeight = 0;
   while (tag.next != null)
   {
      if(tag.data.getInt("top") + tag.data.getInt("height") > maxHeight)
      {
         maxHeight = tag.data.getInt("top") + tag.data.getInt("top"); 
      }
      
      tag = tag.next;
   } 
   
   return tag.data.getInt("top") + tag.data.getInt("height");
}

