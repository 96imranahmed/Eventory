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
if (array_key_exists('accepted', $_POST)) {
    $accepted = boolval(filter_input(INPUT_POST, 'accepted'));
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
        //Do only if user has notification
        $check = $connection->ListCheck($connectinfo, "Notifications", $profid, "groups_pending", $groupid);
        $checkdeclined = $connection->ListCheck($connectinfo, "Profiles", $profid, "groups_declined", $groupid);
        $checkleft = $connection->ListCheck($connectinfo, "Profiles", $profid, "groups_left", $groupid);
        if ($check == true || $checkdeclined == true || $checkleft == true) {
            $targetvalues = $connection->GetValue($connectinfo, "Groups", $groupid, "people_added");
            $targetvaluesarray = unserialize($targetvalues);
            $targetid = ReturnTargetID($targetvaluesarray, $profid);
            if ($accepted) {
                //Add on to people accepted
                $connection->AddtoList($connectinfo, "Groups", $groupid, "people_accepted", $profid); //Add to group list of accepted friends
                $connection->AddtoList($connectinfo, "Profiles", $profid, "groups_accepted", $groupid); //Add to profile list of accepted groups
                $connection->RemoveItemfromList($connectinfo, "Notifications", $profid, "groups_pending", $groupid, "groupid");
                //(Notify group inviter that a new user has accepted group request?
                if ($checkdeclined == false && $checkleft == false) {
                    CreateNotification(2, $connectinfo, $targetid, $profid, $groupid);
                } else {
                    //Remove from list of left groups
                    if ($checkleft) {
                        $connection->RemovefromList($connectinfo, "Profiles", $profid, "groups_left", $groupid);
                    }
                    if ($checkdeclined) {
                        $connection->RemovefromList($connectinfo, "Profiles", $profid, "groups_declined", $groupid);
                    }
                }
            } else {
                if ($check == true && $checkdeclined == false && $checkleft == false) {
                    //Add on to people declined
                    $connection->AddtoList($connectinfo, "Profiles", $profid, "groups_declined", $groupid); //Add to profile list of declined group
                    $connection->RemoveItemfromList($connectinfo, "Notifications", $profid, "groups_pending", $groupid, "groupid"); //Clear "pending" notification
                    //(Notify group inviter that a new user has declined group request?)
                    CreateNotification(3, $connectinfo, $targetid, $profid, $groupid);
                }
            }
        } else {
            $check = $connection->ListCheck($connectinfo, "Groups", $groupid, "people_accepted", $profid);
            if ($check) {
                echo "Error - user is already in group";
            } else {
                echo "Error - user wasn't invited to this group";
            }
        }
    } else {
        echo "Error - authorization mismatch";
    }
} else {
    echo "Error - invalid supplied post data (not enough info?)";
}

function ReturnTargetID($inputarray, $checkvalue) { //Returns invitee's inviter's ID
    foreach ($inputarray as $currentkey => $currentvalue) {
        if (in_array($checkvalue, $currentvalue)) {
            return $currentkey;
        }
    }
}
