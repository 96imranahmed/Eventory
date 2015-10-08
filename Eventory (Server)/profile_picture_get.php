<?php

$safe = true;
include 'connect.php';
$connection = new Connect();
$connectinfo = $connection->GetConnection();
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
if (array_key_exists('id', $_POST)) {
    $idarray = filter_input(INPUT_POST, 'id', FILTER_DEFAULT, FILTER_REQUIRE_ARRAY);
    if (count($idarray) < 1) {
        $safe = false;
    }
} else {
    $safe = false;
}
if ($safe) {
    $authenticated = $connection->Verify($connectinfo, $profid, $token);
    if ($authenticated) {
        $output = [];
        foreach ($idarray as $id) {
            $row = $connection->GetRow($connectinfo, 2, $id);
            $data = file_get_contents($row['url']);
            $remoteImage = $row['url'];
            $imginfo = getimagesize($remoteImage);
            header("Content-type: ". $imginfo['mime']);
            readfile($remoteImage);
            $currentprofile = array("Profid" => $id, "Data" => $remoteimage);
            $output[] = $currentprofile;
        }
        echo json_encode($output);
    } else {
        echo "Error - authorization mismatch";
    }
} else {
    echo 'Error - invalid supplied post data (not enough info?)';
}