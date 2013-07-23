<?php
$logged = false;
$authorized = false;
/*
if(isset($_REQUEST['done']))
{
	$done = $_REQUEST['done'];
}
else
{
	$done = "";
}
*/
if ( isset($_REQUEST['email']) && isset($_REQUEST['password']) )
{
	$email = $_REQUEST['email'];
	$passw = $_REQUEST['password'];
	$out = exec("ruby system/handler.rb adminlogin \"$email\" \"$passw\"");
	if ( $out == "OK" )
	{
		$authorized = true;
		//$done = $done + "</br>Logged as admin";
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
				exec("ruby system/handler.rb power");
				//$done = $done + "</br>Power toggle";
			}
			if ( $action == "banip" && isset($_REQUEST['ban_ip']))
			{
				$ip = $_REQUEST['ban_ip'];
				if ( $ip != "" ) 
				{
					exec("ruby system/handler.rb banip $ip");
					//$done = $done + "</br>Banned ip: $ip";
				}
			}
			
			if ( $action == "register" && isset($_REQUEST['name_reg']) && isset($_REQUEST['pass_reg']))
			{
				$name = $_REQUEST['name_reg'];
				$pass = $_REQUEST['pass_reg'];
				if ( $name != "" )
				{
					exec("ruby system/handler.rb register $name $pass");
					//$done = $done + "</br>added user $name";
				}
			}
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
    if ( $authorized )
    {
	  echo "<a href='javascript:$(\"#statusbox\").toggle(\"slow\")'>Status</a></br>";
	  echo "<div id='statusbox' class='box'>";
      $out = Array();
	  exec("ruby system/handler.rb status", $out);
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
	  exec("ruby system/handler.rb ipbanned", $out);
	  foreach($out as $line)
	  {
		echo $line;
	  }
	  echo "</div>";
	  echo "<a href='javascript:$(\"#ipAllowed\").toggle(\"slow\")'>ip Allowed</a></br>";
	  echo "<div id='ipAllowed' class='box'>";
	  echo "Lista ip permessi: </br>- ";
	  $out = Array();
	  exec("ruby system/handler.rb ipallowed", $out);
	  foreach($out as $line)
	  {
		echo $line;
	  }
	  echo "</div>";
	  echo "<a href='javascript:$(\"#control\").toggle(\"slow\")'>Control Panel</a>";
	  echo "<div id='control' class='box'>";
	  echo "<table><tr><td><form method='post'><input type='hidden' name='email' value='" . $_REQUEST['email'] . "'>
			<input type='hidden' name='password' value='" . $_REQUEST['password'] . "'>
			<input type='hidden' name='action' value='off'><input type='submit' value='Spegni'>" . 
			// "<input type='hidden' name='done' value='$done'>" . 
			"</form></td>
			</tr></table>
			<table><tr><td><form method='post'><input type='hidden' name='email' value='" . $_REQUEST['email'] . "'>
			<input type='hidden' name='password' value='" . $_REQUEST['password'] . "'>
			<input type='hidden' name='action' value='banip'>
			<tr>
			<td colspan='2'>Banna Ip:</td>
			<td><input type='text' name='ban_ip'></td>
			</tr></table>" .
			// "<input type='hidden' name='done' value='$done'>" .
			"</form></br>
			<form method='post'><input type='hidden' name='action' value='register'></br>New User</br>
			<table><tr>
			<td>Username</td><td>Password</td>
			</tr><tr>
			<td><input type='text' name='name_reg'></td>
			<td><input type='password' name='pass_reg'</td>
			</tr><tr><td colspan='2'><input type='submit' value='Aggiungi'></table>
			<input type='hidden' name='email' value='" . $_REQUEST['email'] . "'>
			<input type='hidden' name='password' value='" . $_REQUEST['password'] . "'>" . /*"
			<input type='hidden' name='done' value='$done'> " . */
			"</form></div>
			";
	  
	  echo "<script>
		$(\"#statusbox\").hide();
		$(\"#ipBanned\").hide();
		$(\"#control\").hide();
		$(\"#ipAllowed\").hide();
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
  ?></br>
  <div id="console">
	Console: 
	<?php
		// echo $done;
	?>
  </div>
  </center>
</body>
</html>
