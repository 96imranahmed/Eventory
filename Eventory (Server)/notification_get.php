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
if ($safe) {
    $authenticated = $connection->Verify($connectinfo, $profid, $token);
    if ($authenticated) {
        $notificationarray = [];
        $row = $connection->GetRow($connectinfo, "Notifications", $profid);
        foreach (array_values($row) as $value) {
            if ($value == null || $value == "") {
            } else {
                $notificationarray = $notificationarray + unserialize($value);
            }
        }
        echo json_encode($notificationarray);
        foreach (array_keys($row) as $value) {
            $connection->SetRead($connectinfo, $profid, $value);
        }
    } else {
        echo "Error - authorization mismatch";
    }
} else {
    echo 'Error - invalid supplied post data (not enough info?)';
}