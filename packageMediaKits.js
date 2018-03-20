var PACKAGES_DIR = 'packages';
var SITE_DIR = 'site';
var INCLUDE_DIR = 'include';
var EXPORT_DIR = 'export';
var EXCLUDE = [];

var templates = ['pdf', 'svg', 'png'];
var mediaKit = {};

echo('---------------------------------------');

if(test('-d', PACKAGES_DIR)) {
  echo('Deleting previous packages');
  echo('---------------------------------------');
  rm('-rf', PACKAGES_DIR);
}

if(test('-d', SITE_DIR)) {
  echo('Deleting previous Site');
  echo('---------------------------------------');
  rm('-rf', SITE_DIR);
}

mkdir(PACKAGES_DIR);
mkdir(SITE_DIR);

templates.forEach(function(template) {
	echo('Packaging ' + template.toUpperCase() + ' files:');
	var templateFileType = template.toLowerCase();
	ls(EXPORT_DIR + '/' + template + '/*.' + templateFileType).forEach(function(file) {
		var languageRAW = file.split('_');
		var language = languageRAW[languageRAW.length-1].split('.')[0];

		var excluded = EXCLUDE.indexOf(language) >= 0;

		if(!excluded) {
			if(!mediaKit.hasOwnProperty(language.toLowerCase()))
				mediaKit[language.toLowerCase()] = [];

			mediaKit[language.toLowerCase()].push({label: 'Media Kit in ' + template, file: getPackageName(template, language) + '.zip'});

			echo ('Making ' + language + '...');

			var languageDir = PACKAGES_DIR + '/' + language;
			mkdir(languageDir);
			cp(INCLUDE_DIR + '/' + template +'/*', languageDir);
			cp(file, languageDir + '/Modern Agile Wheel.' + templateFileType);

			if(template === 'svg') {
				cp(file, SITE_DIR + '/modern_agile_wheel_' + language.toLowerCase() + '.' + templateFileType);
			}

			cd(languageDir);
			exec('zip -X ../' + getPackageName(template, language) + '.zip *', {silent:true});
			cd('../..');

			rm('-rf', languageDir);
		}
	});
	echo('Done!');
	echo('---------------------------------------');
});

echo('Generating data file...');
var json = ShellString(JSON.stringify(mediaKit));
json.to(PACKAGES_DIR + '/mediaKit.json');

echo('Deleting temp work files');
echo('---------------------------------------');
for(var d=0; d<templates.length; d++) {
	//var dir = EXPORT_DIR + '/' + templates[d];
  var dir = EXPORT_DIR;
	rm('-rf', dir);
}

echo('Finished!');

function getPackageName(template, language) {
	return 'MediaKit' + '_' + template.toUpperCase() + '_' + language;
}
