<?php
include_once 'connect.php';
function CreateNotification($type, $pdo, $targetid, $starterid, $valuein) {
    $connection = new Connect();
    if ($type == 0) {
        //Notify that a new friend has joined -> Don't actually do anything (Just added to friends_new_unseen in Notifications in profile.php)
    } elseif ($type == 1) {
        //Notify that you have been invited to a new group
        $connection->AddtoList($pdo, "Notifications", $targetid, "groups_pending_unread", $valuein);
        $groupname = $connection->GetNamebyId($pdo, $valuein, 1);
        $notification = strtok(($connection->GetNamebyId($pdo, $starterid, 0)), " ") . ' invited you to join ' . $groupname;
        PasstoParse($targetid, $notification);
    } elseif ($type == 2) {
        //Notify that a person has accepted your group join request
        $check = $connection->ListCheck($pdo, "Groups", $valuein, "people_accepted", $targetid);
        //Check person is still inside group
        if ($check) {
            $groupname = $connection->GetNamebyId($pdo, $valuein, 1);
            $notification = strtok(($connection->GetNamebyId($pdo, $starterid, 0)), " ") . ' accepted your request to join ' . $groupname;
            PasstoParse($targetid, $notification);
        }
    } elseif ($type == 3) {
        //Notify that a person has declined your group join request
        $check = $connection->ListCheck($pdo, "Groups", $valuein, "people_accepted", $targetid);
        //Check person is still inside group
        if ($check) {
            $groupname = $connection->GetNamebyId($pdo, $valuein, 1);
            $notification = strtok(($connection->GetNamebyId($pdo, $starterid, 0)), " ") . ' rejected your request to join ' . $groupname;
            PasstoParse($targetid, $notification);
        }
    } elseif ($type == 4) {
        //Notify that a person has been made a group admin
        $groupname = $connection->GetNamebyId($pdo, $valuein, 1);
        $notification = "You have been made the admin of '$groupname'";
        PasstoParse($targetid, $notification);
    }
}

function PasstoParse($targetid, $notification) { 
    $connection = new Connect();
    $connectinfo = $connection->GetConnection();
    $name = $connection->GetNamebyId($connectinfo, $targetid, 0);
    echo '<p>Directed to: '.$name.' - '. $notification . '</p>';
}