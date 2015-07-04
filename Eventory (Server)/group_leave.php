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
if ($safe) {
    $authenticated = $connection->Verify($connectinfo, $profid, $token);
    if ($authenticated) {
        //Do only if user is part of group
        $check = $connection->ListCheck($connectinfo, "Groups", $groupid, "people_accepted", $profid);
        if ($check) {
            $starterid = $connection->GetValue($connectinfo, "Groups", $groupid, "starter");
            if (intval($starterid) == intval($profid)) {
                $connection->RemovefromList($connectinfo, "Groups", $groupid, "people_accepted", $profid);
                $connection->AddtoList($connectinfo, "Profiles", $profid, "groups_left", $groupid);
                //Designate a new admin
                $peopleaccepted = $connection->GetValue($connectinfo, "Groups", $groupid, "people_accepted");
                if ($peopleaccepted == null || $peopleaccepted == "") {
                    //(DEAL HERE - what would you do - delete the group???) - YEAH DELETE GROUP INSERT CODE
                    $invitedlist = $connection->GetValue($connectinfo, "Groups", $groupid, "people_requested");
                    $invitedarray = explode(";", $invitedlist);
                    if (is_array($invitedarray) || is_object($invitedarray)) {
                        foreach ($invitedarray as $invitee) {
                            $connection->RemovefromList($connectinfo, "Profiles", $invitee, "groups_accepted", $groupid);
                            $connection->RemovefromList($connectinfo, "Profiles", $invitee, "groups_declined", $groupid);
                            $connection->RemovefromList($connectinfo, "Profiles", $invitee, "groups_left", $groupid);
                            $connection->RemovefromList($connectinfo, "Notifications", $invitee, "groups_pending", $groupid);
                            $connection->RemovefromList($connectinfo, "Notifications", $invitee, "groups_pending_unread", $groupid);
                        }
                    }
                    $sql = $connectinfo->prepare("DELETE FROM Groups WHERE id ='$groupid'");
                    $sql->execute();
                } else {
                    $peopleacceptedarray = explode(";", $peopleaccepted);
                    $peopleaccepted = $peopleacceptedarray[0];
                    CreateNotification(4, $connectinfo, $peopleaccepted, null, $groupid);
                    $postsql = $connectinfo->prepare("UPDATE Groups SET starter='$peopleaccepted' WHERE id='$groupid'");
                    $postsql->execute();
                }
                $connection->RemovefromList($connectinfo, "Profiles", $profid, "groups_accepted", $groupid);
            } else {
                $connection->RemovefromList($connectinfo, "Groups", $groupid, "people_accepted", $profid);
                $connection->AddtoList($connectinfo, "Profiles", $profid, "groups_left", $groupid);
                $connection->RemovefromList($connectinfo, "Profiles", $profid, "groups_accepted", $groupid);
            }
        } else {
            echo "Error - user wasn't in this group";
        }
    } else {
        echo "Error - authorization mismatch";
    }
} else {
    echo 'Error - invalid supplied post data (not enough info?)';
}
    