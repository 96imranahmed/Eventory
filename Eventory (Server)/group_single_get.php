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
if (array_key_exists('groupid', $_POST)) {
    $groupid = filter_input(INPUT_POST, 'groupid');
} else {
    $safe = false;
}
if ($safe) {
    $authenticated = $connection->Verify($connectinfo, $profid, $token);
    if ($authenticated) {
                $row = $connection->GetRow($connectinfo, 0, $groupid);
                $name = $row["name"];
                $id = $row["id"];
                $currentacceptedarray = explode(";", $row["people_accepted"]);
                $currentinvited = explode(";", $row["people_requested"]);
                $starter = $row["starter"];
                if ($starter == $profid) {
                    $admin = 1;
                } else {
                    $admin = 0;
                }
                $currentgroup = array("Name" => $name, "GroupID" => $id, "Members" => $currentacceptedarray, "Invited" => $currentinvited, "Admin" => $admin);
                echo json_encode($currentgroup);
    } else {
        echo "Error - authorization mismatch";
    }
} else {
    echo 'Error - invalid supplied post data (not enough info?)';
}