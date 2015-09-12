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
if (array_key_exists('type', $_POST)) {
    $type = filter_input(INPUT_POST, 'type');
} else {
    $safe = false;
}
if ($safe) {
    $authenticated = $connection->Verify($connectinfo, $profid, $token);
    if ($authenticated) {
        if (type == 0) {
            //Get accepted groups
           $groupstring = $connection->GetValue($connectinfo, 2, $profid, "groups_accepted");
            } elseif (type == 1) {
            //Get declined groups
            $groupstring = $connection->GetValue($connectinfo, 2, $profid, "groups_declined");
        } elseif (type == 2) {
            //Get left groups
            $groupstring = $connection->GetValue($connectinfo, 2, $profid, "groups_left");
        }
        if ($groupstring == 0 || $groupstring == null) {
            echo null;
        } else {
            $grouparray = explode(";", $groupstring);
            $returnarray = array();
            foreach ($grouparray as $currentid) {
                $row = $connection->GetRow($connectinfo,0, $currentid);
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
                $returnarray[$currentid] = $currentgroup;
            }
            echo json_encode($returnarray);
        }
    } else {
        echo "Error - authorization mismatch";
    }
} else {
    echo 'Error - invalid supplied post data (not enough info?)';
}