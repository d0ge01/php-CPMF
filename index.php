<?php
$logged = false;
$authorized = false;
if ( isset($_REQUEST['email']) && isset($_REQUEST['password']) )
{
	$email = $_REQUEST['email'];
	$passw = $_REQUEST['password'];
	$out = exec("ruby system/acceptlogin.rb login \"$email\" \"$passw\"");
	if ( $out == "OK" )
	{
		$authorized = true;
	}
	else {
		$authorized = false;
	}
	if ( $authorized )
	{
		if(isset($_REQUEST['action']))
		{
			$action = $_REQUEST['action'];
			if ( $action == "off" )
			{
				exec("ruby system/acceptlogin.rb deactivate");
			}
			if ( $action == "on" )
			{
				exec("ruby system/acceptlogin.rb activate");
			}
		}
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
<body><center>
  <?php
    if ( $authorized )
    {
	  echo "<a href='javascript:$(\"#statusbox\").toggle(\"slow\")'>Status</a></br>";
	  echo "<div id='statusbox' class='box'>";
      $out = Array();
	  exec("ruby system/acceptlogin.rb status", $out);
	  foreach($out as $line)
	  {
		echo $line;
	  }
	  echo "</div>";
	  unset($out);
	  $out = Array();
	  echo "<a href='javascript:$(\"#ipBanned\").toggle(\"slow\")'>ip Banned</a></br>";
	  echo "<div id='ipBanned' class='box'>";
	  echo "Lista ip bannati: </br>- ";
	  exec("ruby system/acceptlogin.rb ipbanned", $out);
	  foreach($out as $line)
	  {
		echo $line;
	  }
	  echo "</div>";
	  echo "<a href='javascript:$(\"#control\").toggle(\"slow\")'>Control Panel</a>";
	  echo "<div id='control' class='box'>";
	  echo "<table><tr><td><form method='post'><input type='hidden' name='email' value='" . $_REQUEST['email'] . "'>
			<input type='hidden' name='password' value='" . $_REQUEST['password'] . "'>
			<input type='hidden' name='action' value='off'><input type='submit' value='Spegni'></form></td>
			<td><form method='post'><input type='hidden' name='email' value='" . $_REQUEST['email'] . "'>
			<input type='hidden' name='password' value='" . $_REQUEST['password'] . "'>
			<input type='hidden' name='action' value='on'><input type='submit' value='Accendi'></form></td>
			</tr></table>";
	  
	  echo "<script>
		$(\"#statusbox\").hide();
		$(\"#ipBanned\").hide();
		$(\"#control\").hide();
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
