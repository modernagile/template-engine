# template-engine

This application seems to be generated or based on [Processing](https://processing.org/). We're not sure how to regenerate it, or how it was originally created.

## You'll get by with a little help from a friend.
While most of what is needed is checked into this repo, you will need to install the following homebrew macOS package:

```brew install pdf2svg```

Later, you will need to know and/or get a copy of the full path (most likely something like this): 
```/usr/local/Cellar/pdf2svg/0.2.3_6/bin/pdf2svg```

To paste into the UI to specify when templatr runs as described below.

NOTE: Contrary to our original understanding, the tool _IS_ needed for correct 
rendering of the SVG image.

## Go with the flow.

Add your translations to modern_agile_wheel_3L.json

To run on mac, open the templatr in templatr/build/application.macosx (or whatever is appropriate for you).

Check the boxes for the file types you want to generate.

Fill in the copied path for and/or select the binary for pdf2svg described above.

Select the json file you edited with your translation.

Wait. The media kit and images will be generated.

### Package
You will need to run packageMediaKit (via node, which expects shelljs package to be installed).

This js program will create package/*zip files for you. You can then take the .zip files and apply them to the ModernAgile site.

## Then what?
You will want to copy the generated media files to the ModernAgile site and continue there as explained in that README.md file.

