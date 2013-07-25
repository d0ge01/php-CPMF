<?php
/*
 * This file is a part of CPMF
 */
 
$host =  "localhost 12345"
$todo = 0;
$buff = ""

if ( isset($_REQUEST['hash']) )
{
	$todo = 1;
	$hash = $_REQUEST['hash'];
	
	$out = exec("ruby system/handler.rb $host verify $hash");
	if ( $out == "NOONE" )
	{
		$buff = "Hash not valid :(";
	}else
	{
		if ( $out == "OK" )
		{
			$buff = "Email confirmed";
		}
		if ( $out == "FAIL" )
		{
			$buff = "Something wrong with verification, plz retry";
		}
	}
}
?>

<!DOCTYPE html>
<html>
<head>
  <title>Captive Portal Control Panel</title>
  <script src="system/jquery.js"></script>
  <script src="system/main.js"></script>

  <link rel="stylesheet" type="text/css" href="css/main.css" id="maincss" />

  <meta http-equiv="content-type" content="text/html; charset=UTF-8" />
</head>
<body><center>
	<?php
		if ( $todo == 0 )
		{
			echo 'Verification Page ' .
				 '<form method="post"> ' .
				 '   Hash: <input type="text" name="hash"> ' . 
				 '   <input type="submit" value="Verify">' .
				 '</form>';
		}
		else
		{
			echo $buff;
		}
	?>
</center>
</body></html>
		