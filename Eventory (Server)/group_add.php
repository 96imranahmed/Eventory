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
if (array_key_exists('id', $_POST)) {
    $idarray = filter_input(INPUT_POST, 'id', FILTER_DEFAULT, FILTER_REQUIRE_ARRAY);
    if (count($idarray) < 1) {
        $safe = false;
    } else {
        $idstring = implode(';', $idarray);
    }
} else {
    $safe = false;
}
if ($safe) {
    $authenticated = $connection->Verify($connectinfo, $profid, $token);
    if ($authenticated) {
        //Do only if user is part of group & Group exists
        $check = $connection->ListCheck($connectinfo, "Groups", $groupid, "people_accepted", $profid);
        $groupexists = $connectinfo->prepare("SELECT id from Groups where id='$groupid'");
        $groupexists->execute();
        //Check if users supplied aren't already invited (Method below performs delete)
        $idtodelete = array();
        foreach ($idarray as $id) {
            $checkinvite = $connection->ListCheck($connectinfo, "Groups", $groupid, "people_requested", $id); //Requested (invited) people check
            if ($checkinvite) {
                $idtodelete[] = $id;
            }
        }
        foreach ($idtodelete as $key) {
            $keyToDelete = array_search($key, $idarray);
            unset($idarray[$keyToDelete]);
        }
        //ID's deleted
        if (count($idarray) < 1) {
           echo "Error - all the people invited were duplicates";
        } else {
            if ($check && ($groupexists->rowCount() > 0)) {
                $currentarray = [];
                $currentarray[$profid] = $idarray;
                $current = serialize($currentarray);
                $postsql = $connectinfo->prepare("UPDATE Groups SET people_added='$current' WHERE id='$groupid'");
                $postsql->execute();
                foreach ($idarray as $id) {
                    CreateNotification(1, $connectinfo, $id, $profid, $groupid); //Send them a notification
                    $connection->AddtoList($connectinfo, "Groups", $groupid, "people_requested", $id);
                }
            } else {
                if ($check) {
                    echo "Error - group doesn't exist";
                } else {
                    echo "Error - original user was not a part of this group";
                }
            }
        }
    } else {
        echo "Error - authorization mismatch";
    }
} else {
    echo 'Error - invalid supplied post data (not enough info?). Alternatively, no people were added?';
}