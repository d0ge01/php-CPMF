<?php
// Stringhe
$strErrorDb = "Errore nella connessione o gestione database...</br>";
$strAuthor = "Salvatore Criscione";
$strName = "CPMF";

// Variabili
//
//
$authorized = false;
$logged = false;

if ( !isset($_REQUEST['email']) && !isset($_REQUEST['password']))
{
  $authorized = false;
}
else
{
  $authorized = true;
}


if ($authorized)
{
  $sq = sqlite_open("login.db", 0666, $sqlite_error);
  if(!$sq)
  {
    die($strErrorDb . $sqlite_error );
  }
  $result = sqlite_query($sq, "SELECT * FROM logindata WHERE utente=". $_REQUEST['email'] . " AND password=" . $_REQUEST['password']);

  $i = 0;
  while ( $data = sqlite_fetch_array($result))
  {
    $i++;
  }
  if ( $i == 0 )
  {
    $logged = true;
  }else{
    $logged = false;
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
          </div>';
   }
  ?>
</body>
</html>
