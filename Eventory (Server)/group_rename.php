<?php

$safe = true;
include_once 'connect.php';
include_once 'notification_create.php';
$connection = new Connect();
$connectinfo = $connection->GetConnection();
if (array_key_exists('groupid', $_POST)) {
    $groupid = filter_input(INPUT_POST, 'groupid');
} else {
    $safe = false;
}
if (array_key_exists('profid', $_POST)) {
    $profid = filter_input(INPUT_POST, 'profid');
} else {
    $safe = false;
}
if (array_key_exists('token', $_POST)) {
    $token = filter_input(INPUT_POST, 'token');
} else {
    $safe = false;
}
if (array_key_exists('name', $_POST)) {
    $name = filter_input(INPUT_POST, 'name');
} else {
    $safe = false;
}
if ($safe) {
    $authenticated = $connection->Verify($connectinfo, $profid, $token);
    if ($authenticated) {
        $row = $connection->GetRow($connectinfo, "Groups", $groupid);
        $admin = $row["starter"];
        if ($admin == $profid) {
            $prepsql = $connectinfo->prepare("INSERT INTO Groups (id, name) VALUES ('$groupid','$name') ON DUPLICATE KEY UPDATE name=VALUES(name)");
            $prepsql->execute();
        } else {
            echo "Error - non-admin cannot rename group!";
        }
    } else {
        echo "Error - authorization mismatch";
    }
} else {
    echo 'Error - invalid supplied post data (not enough info?)';
}