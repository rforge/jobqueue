
<!-- This is the project specific website template -->
<!-- It can be changed as liked or replaced by other content -->

<?php

$domain=ereg_replace('[^\.]*\.(.*)$','\1',$_SERVER['HTTP_HOST']);
$group_name=ereg_replace('([^\.]*)\..*$','\1',$_SERVER['HTTP_HOST']);
$themeroot='r-forge.r-project.org/themes/rforge/';

echo '<?xml version="1.0" encoding="UTF-8"?>';
?>
<!DOCTYPE html
	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en   ">

  <head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
	<title><?php echo $group_name; ?></title>
	<link href="http://<?php echo $themeroot; ?>styles/estilo1.css" rel="stylesheet" type="text/css" />
  </head>

<body>

<!-- R-Forge Logo -->
<table border="0" width="100%" cellspacing="0" cellpadding="0">
<tr><td>
<a href="http://r-forge.r-project.org/"><img src="http://<?php echo $themeroot; ?>/imagesrf/logo.png" border="0" alt="R-Forge Logo" /> </a> </td> </tr>
</table>


<!-- get project title  -->
<!-- own website starts here, the following may be changed as you like -->

<?php if ($handle=fopen('http://'.$domain.'/export/projtitl.php?group_name='.$group_name,'r')){
$contents = '';
while (!feof($handle)) {
	$contents .= fread($handle, 8192);
}
fclose($handle);
//echo $contents;  // DISABLED
} ?>

<!-- end of project description -->

<h1>The jobqueue Package - a Generic Asynchronous Job Queue Implementation for R</h1>

<p> The jobqueue package is meant to provide an easy-to-use interface that allows to queue computations for background evaluation
while the calling R session remains responsive. It is based on a 1-node socket cluster from the parallel package. The package provides
a way to do basic threading in R.</p>

<p> The main focus of the package is on an intuitive and easy-to-use interface for the job queue programming construct. As it is somewhat
subjective what is actually "intuitive", feel free to post your suggestions to the jobqueue-help mailing list on the
<a href="http://<?php echo $domain; ?>/projects/<?php echo $group_name; ?>/"><strong>project summary page</strong></a>.</p>

<p> Typical applications include: background computation of lengthy tasks (such as data sourcing, model fitting),
simple/interactive parallelization (if you have 5 different jobs, move them to up to 5 different job queues), and concurrent task scheduling
in more complicated R programs. <a href="https://www.bramblecloud.com">Bramblecloud's cloud computing service for R</a> uses the jobqueue
package as an asynchronous wrapper for synchronous remote connections.</p>

<p> Click <a href="/jobqueue-manual.pdf">here</a> for the package documentation.</p>

</body>
</html>
