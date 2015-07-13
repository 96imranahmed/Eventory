<?php

$safe = true;
include_once "connect.php";
$connection = new Connect();
$connectinfo = $connection->GetConnection();
//Start Program
if (array_key_exists('profid', $_POST)) {
    $profid = filter_input(INPUT_POST, 'profid');
//echo '<p>ID: '.$id.'</p>';
} else {
//echo '<p>ID not supplied</p>';
    $safe = false;
}
if (array_key_exists('name', $_POST)) {
    $name = filter_input(INPUT_POST, 'name');
//echo '<p>Name: '.$name.'</p>';
} else {
//echo '<p>Name not supplied</p>';
    $safe = false;
}
if (array_key_exists('url', $_POST)) {
    $profurl = filter_input(INPUT_POST, 'url');
//echo '<p>URL: '.$profurl.'</p>';
} else {
//echo '<p>URL not supplied</p>';
    $safe = false;
}
if (array_key_exists('token', $_POST)) {
    $token = filter_input(INPUT_POST, 'token');
//echo '<p>Token: '.$token.'</p>';
} else {
// echo '<p>Token not supplied</p>';
    $safe = false;
}
if (array_key_exists('id', $_POST)) {
    $idarray = filter_input(INPUT_POST, 'id', FILTER_DEFAULT, FILTER_REQUIRE_ARRAY);
} else {
    $idarray = [];
}
$check = $connection->TokenVerify($profid, $token);
if ($check) {
    if ($safe) {
        try {
            $profilecheck = $connectinfo->prepare("SELECT id from Profiles where id='$profid'");
            $profilecheck->execute();
            if ($profilecheck->rowCount() >= 1) {
                //Profile already exists
            } else {
                //Notify friends that person has joined
                foreach ($idarray as $id) {
                    $connection->AddtoList($connectinfo, "Notifications", $id, "friends_new_unseen", $profid);
                }
            }
            $prepsql = $connectinfo->prepare("INSERT INTO Profiles (id, name, token, url) VALUES ('$profid','$name','$token','$profurl') ON DUPLICATE KEY UPDATE name=VALUES(name), token=VALUES(token), url=VALUES(url)");
            $prepsql->execute();
            $notifysql = $connectinfo->prepare("INSERT INTO Notifications (id, friends_new_unseen) VALUES ('$profid', null) ON DUPLICATE KEY UPDATE id=id");
            $notifysql->execute();
        } catch (PDOException $e) {
            echo 'Error - ' . $e->GetMessage();
        }
    } else {
        echo 'Error - invalid supplied post data (not enough info?)';
    }
} else {
    echo 'Error - invalid authorization token';
}