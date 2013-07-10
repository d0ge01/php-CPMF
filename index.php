<?php
$logged = false;
$authorized = false;
if ( isset($_REQUEST['email']) && isset($_REQUEST['password']) )
{
	$email = $_REQUEST['email'];
	$passw = $_REQUEST['password'];
	
	$out = exec("ruby system/acceptlogin.rb \"$email\" \"$passw\"");
	if ( $out == "OK" )
	{
		$authorized = true;
	}
	else {
		$authorized = false;
	}
}
?>

<!DOCTYPE html>
<html>
<head>
  <title>Captive Portal Authentication</title>
  <script src="system/jquery.js"></script>
  <script src="system/main.js"></script>

  <link rel="stylesheet" type="text/css" href="css/main.css" id="maincss" />

  <meta http-equiv="content-type" content="text/html; charset=UTF-8" />
</head>
<body>
  <?php
    if ( $authorized )
    {
      echo "
            <center>
            Non dovresti essere più su questa pagina, in ogni caso se continui a visualizzarla premi
            <a href='http://www.google.com'>qua</a>.
            </center>
           ";

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
  ?>
</body>
</html>
