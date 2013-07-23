<?php

/*
	This file is a part of CPMF
*/

$logged = false;
$authorized = false;
$host =  "localhost 12345"


if ( isset($_REQUEST['email']) && isset($_REQUEST['password']) )
{
	$email = $_REQUEST['email'];
	$passw = $_REQUEST['password'];
	$out = exec("ruby system/handler.rb $host login \"$email\" \"$passw\"");
	if ( $out == "OK" )
	{
		$authorized = true;
		exec("ruby system/handler.rb $host autorize " . $_SERVER['REMOTE_ADDR'] );
	}
	else {
		$authorized = false;
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
    if ( $authorized )
    {
	  echo "Non dovresti più vedere questa pagina...</br>";
	  echo "<script>
				function redirect() {
					window.location.href = 'https://www.google.com';
				}
				setTimeout(\"redirect()\", 4000);
			</script>";
    }else{
      echo '
          <center> Autenticazione necessaria... </center>
          <div id="logindialog">
            <form method="post">
              <input type="text" name="email"></br>
              <input type="password" name="password"></br>
              <input type="submit" value="Login">
            </form>
          </div></center>';
   }
  ?></center>
</body>
</html>
