<?php

$safe = true;
include_once 'connect.php';
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
if ($safe) {
    $authenticated = $connection->Verify($connectinfo, $profid, $token);
    if ($authenticated) {
        $row = $connection->GetRow($connectinfo, 0, $groupid);
        $admin = $row["starter"];
        $invitedlist = $row["people_requested"];
        if ($admin == $profid) {
            $invitedarray = explode(";", $invitedlist);
            if (is_array($invitedarray) || is_object($invitedarray)) {
                foreach ($invitedarray as $invitee) {
                    //Delete all traces of the group brah!
                    $connection->RemovefromList($connectinfo, 2, $invitee, "groups_accepted", $groupid);
                    $connection->RemovefromList($connectinfo, 2, $invitee, "groups_declined", $groupid);
                    $connection->RemovefromList($connectinfo, 2, $invitee, "groups_left", $groupid);
                    $connection->RemoveItemfromList($connectinfo, 1, $invitee, "groups_pending", "groupid:".strval($groupid), "data");
                    $connection->RemoveItemfromList($connectinfo, 1, $invitee, "groups_decision", "groupid:".strval($groupid), "data");             
                }
            }
            $sql = $connectinfo->prepare("DELETE FROM Groups WHERE id = :groupid");
            $sql->execute(array(':groupid' => $groupid));
        } else {
            echo "Error - non-admin cannot delete group!";
        }
    } else {
        echo "Error - authorization mismatch";
    }
} else {
    echo 'Error - invalid supplied post data (not enough info?)';
}