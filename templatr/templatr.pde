import processing.svg.*;
import processing.pdf.*;

import interfascia.*;

GUIController gui;
IFButton importButton;
IFProgressBar progressBar;
IFCheckBoxCustom checkPDF, checkSVG, checkPNG, checkPDF2SVG;
IFLabel exportLabel, pathTo, pathToValue, status;
float progress = 0;
boolean processing = false;

String templateFile;
String pdf2svgPath = "";

JSONObject templateData;
PShape templateShape;
int templateWidth, templateHeight;

String DEFAULT_FONT = "OpenSans.otf";
final String EXPORT_FOLDER = "/export";
String EXPORT_PATH = "/export";
String ROOT_FOLDER;

HashMap<String,Integer> alignment = new HashMap<String,Integer>();
HashMap<String,String> renderer = new HashMap<String,String>();

void setup() {
  size(600, 200);
  
  alignment.put("TOP", TOP);
  alignment.put("CENTER", CENTER);
  
  renderer.put("svg", SVG);
  renderer.put("pdf", PDF);

  gui = new GUIController (this);
  int buttonWidth = 200;
  int progressBarWidth = width-40;
  importButton = new IFButton ("Select data file", width/2-buttonWidth/2, 20, buttonWidth, 17);
  importButton.addActionListener(this);
  
  exportLabel = new IFLabel("Export in:", 20, 100);
  checkPDF = new IFCheckBoxCustom("PDF", 20, 120);
  checkSVG = new IFCheckBoxCustom("SVG", 80, 120);
  checkPNG = new IFCheckBoxCustom("PNG", 140, 120);
  checkPDF2SVG = new IFCheckBoxCustom("Use PDF2SVG", 250, 100);
  pathTo = new IFLabel("Path:", 250, 120);
  pathToValue = new IFLabel("", 280, 120);
  status = new IFLabel("Status: Waiting for datafile...", 20, 160);
  checkPDF.addActionListener(this);
  checkSVG.addActionListener(this);
  checkPNG.addActionListener(this);
  checkPDF2SVG.addActionListener(this);
  
  checkPDF.select(true);
  checkSVG.select(true);
  checkPNG.select(true);
  
  progressBar = new IFProgressBar(width/2-progressBarWidth/2, 50, progressBarWidth);
  progressBar.setHeight(34);
  
  gui.add (importButton);
  gui.add (progressBar);
  gui.add (exportLabel);
  gui.add (checkPDF);
  gui.add (checkSVG);
  gui.add (checkPNG);
  gui.add (checkPDF2SVG);
  gui.add (pathTo);
  gui.add (pathToValue);
  gui.add (status);
    
  boolean loaded = loadPDF2SVGPath();
  if(loaded) {
    checkPDF2SVG.select(true);
    pathToValue.setLabel(pdf2svgPath);
  }
}

boolean loadPDF2SVGPath() {
  boolean success = false;
  String[] lines = loadStrings("svg2pfpath.cfg");
  if(lines.length > 0 && lines != null) {
    success = true;
    pdf2svgPath = lines[0];
  }
  return success;
}

void clearPDF2SVGPath() {
  pdf2svgPath = "";
  pathToValue.setLabel(pdf2svgPath);
  String[] filePath = new String[0];
  saveStrings(dataPath("")+"/svg2pfpath.cfg", filePath);
}

void actionPerformed (GUIEvent e) {
  if (e.getSource() == importButton) {
    if(!processing) {
      if(checkPDF.isSelected() || checkSVG.isSelected() || checkPNG.isSelected()) {
        processing = true;
        selectInput("Select a file to process:", "processDataFile");
      } else {
        message("Select at least one type of file to export.");
      }
    }
  }
  else if(e.getSource() == checkPDF2SVG) {
    if(checkPDF2SVG.isSelected()) {
      selectInput("Select PDF2SVG Binary", "savePDF2SVGPath");
    } else {
      clearPDF2SVGPath();
    }
  }
}

void draw() {
  background(#CCCCCC);
}

void savePDF2SVGPath(File dataFile) {
  pdf2svgPath = dataFile.getPath();
  pathToValue.setLabel(pdf2svgPath);
  String[] filePath = new String[1];
  filePath[0] = pdf2svgPath;
  saveStrings(dataPath("")+"/svg2pfpath.cfg", filePath);
}

void processDataFile(File dataFile) { 
  if(dataFile == null) {
    processing = false;
    return;
  }
  
  String parentDir = dataFile.getParent();
  ROOT_FOLDER = parentDir;
  File pdfFolder = new File(ROOT_FOLDER + EXPORT_FOLDER + "/pdf");
  File svgFolder = new File(ROOT_FOLDER + EXPORT_FOLDER + "/svg");
  File pngFolder = new File(ROOT_FOLDER + EXPORT_FOLDER + "/png");
  if(checkPDF.isSelected())
    pdfFolder.mkdirs();
  if(checkSVG.isSelected())
    svgFolder.mkdirs();
  if(checkPNG.isSelected())
    pngFolder.mkdirs();
  
  EXPORT_PATH = ROOT_FOLDER + EXPORT_FOLDER;
    
  templateFile = dataFile.getName().replaceFirst("[.][^.]+$", "");
  
  templateData = loadJSONObject(parentDir + "/" + templateFile + ".json");
  templateShape = loadShape(parentDir + "/" + templateData.getString("template"));
  templateWidth = round(templateShape.width);
  templateHeight = round(templateShape.height);
  DEFAULT_FONT = templateData.getString("defaultFont");
  
  JSONArray entries = templateData.getJSONArray("entries");
  
  for (int i = 0; i < entries.size(); i++) {
    JSONObject entry = entries.getJSONObject(i);
    exportEntry(entry);
    progressBar.setProgress(float(i+1)/entries.size());
    message("Converting (" + round(float(i+1)/entries.size()*100) + "%)");
  }
  processing = false;
  message("Conversion finished!");
}

void exportEntry(JSONObject entry) {
  String entryId = entry.getString("id");
  boolean entryIsRTL = entry.getBoolean("rtl", false);
  String entryFont = entry.isNull("font") ? DEFAULT_FONT : entry.getString("font");
  JSONArray entryData = entry.getJSONArray("data");
  JSONObject geometry = entry.isNull("geometry") ? templateData.getJSONObject("defaultGeometry") : entry.getJSONObject("geometry");
  
  String pdfPath = "";
  if(checkPDF.isSelected())
    pdfPath = exportFile("pdf", false, entryId, entryFont, entryIsRTL, entryData, geometry);
  if(checkSVG.isSelected()) {
    if(checkPDF2SVG.isSelected() && checkPDF.isSelected())
      pdf2svg(pdfPath);
    else {
      message(status.getLabel() + "\nPDF Export is unchechecked, reveting to default SVG exporting.");
      exportFile("svg", false, entryId, entryFont, entryIsRTL, entryData, geometry);
    }
  }
  if(checkPNG.isSelected())
    exportFile("png", true, entryId, entryFont, entryIsRTL, entryData, geometry);
}

void message(String s) {
  status.setLabel("Status: " + s);
}

String exportFile(String fileType, boolean save, String entryId, String entryFont, boolean entryIsRTL, JSONArray data, JSONObject geometry) {
  String format = fileType;
  String filePath = EXPORT_PATH + "/" + format + "/" + templateFile + "_" + entryId + "." + format;
  PGraphics graphic = (save) ? createGraphics(templateWidth, templateHeight) : createGraphics(templateWidth, templateHeight, renderer.get(fileType), filePath);
  graphic.beginDraw();
 
  graphic.shape(templateShape, 0, 0, templateWidth, templateHeight);
  for (int i = 0; i < data.size(); i++) {
    JSONArray stringData = data.getJSONArray(i);
    String fieldName = stringData.getString(0);
    String fieldValue = stringData.getString(1);
    if(!geometry.isNull(fieldName)) {
      JSONObject fieldGeometry = geometry.getJSONObject(fieldName);
      PFont myFont = createFont(entryFont, fieldGeometry.getInt("fontSize"));
      graphic.textFont(myFont);
      graphic.textSize(fieldGeometry.getInt("fontSize"));
      graphic.textLeading(fieldGeometry.getInt("leading"));
      graphic.fill(unhex(fieldGeometry.getString("color")));
      graphic.textAlign(alignment.get(fieldGeometry.getString("aligmentX")), alignment.get(fieldGeometry.getString("aligmentY")));
      graphic.text(fieldValue, fieldGeometry.getInt("x"), fieldGeometry.getInt("y"));
    }
  }
  graphic.dispose();
  graphic.endDraw();
  
  if(save)
    graphic.save(filePath);
  
  return filePath;
}

void pdf2svg(String filePath) {
  File f = new File(filePath);
  String filename = f.getName().replaceFirst("[.][^.]+$", "");
  exec(pdf2svgPath, filePath, ROOT_FOLDER + EXPORT_FOLDER + "/svg/" + filename + ".svg");
}