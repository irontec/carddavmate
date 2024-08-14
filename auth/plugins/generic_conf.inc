<?php
	// Server base URL
	$pluginconfig['base_url']=(empty($_SERVER['HTTPS']) ? 'http' : 'https').'://' . $_SERVER['SERVER_NAME'] . "/baikal/";

	// Default values are usually OK
	//  for Davical:
	$pluginconfig['request']='/caldav.php';	// change only if your Davical is not installed into server root directory
	//  for Lion server:
	//$pluginconfig['request']='/principals/users';

	$pluginconfig['timeout']=30;
?>