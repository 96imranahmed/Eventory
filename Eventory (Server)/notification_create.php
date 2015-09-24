<?php
include_once 'connect.php';
function CreateNotification($type, $pdo, $targetid, $starterid, $valuein, $decision = NULL) {
    $connection = new Connect();
    if ($type == 1) {
        //Notify that you have been invited to a new group
        $notification = strtok(($connection->GetNamebyId($pdo, $starterid, 0)), " ") . ' invited you to join ';
        $params = ["sourceid" => $starterid, "date" => time(), "type" => 1, "text" => $notification, "isread" => 0, "data" => "groupid:".strval($valuein)];
        $connection->AddItemtoList($pdo, 1, $targetid, "groups_pending", $params, "data");
        $connection->AddNewtoList($pdo, 1, $targetid, "notification_raw", 1);
    } elseif ($type == 2) {
        //Notify that a person has accepted/denied your group join request
        $check = $connection->ListCheck($pdo,0, $valuein, "people_accepted", $targetid);
        //Check person is still inside group
        if ($check) {
            if ($decision) {
                $notification = strtok(($connection->GetNamebyId($pdo, $starterid, 0)), " ") . ' accepted your invitation to join ';
            } else {
                $notification = strtok(($connection->GetNamebyId($pdo, $starterid, 0)), " ") . ' declined your invitation to join ';
            }
            $params = ["sourceid" => $starterid, "date" => time(), "type" => 2, "text" => $notification, "isread" => 0, "data" => "groupid:".strval($valuein)];
            $connection->AddItemtoList($pdo, 1, $targetid, "groups_decision", $params, "data");
            $connection->AddNewtoList($pdo, 1, $targetid, "notification_raw", 2);           
        }
    } elseif ($type == 3) {
        //Notify that a person has been made a group admin
        $groupname = $connection->GetNamebyId($pdo, $valuein, 1);
        $notification = "You have been made the admin of '$groupname'";
  
    } elseif ($type == 4) {
     
    }
}

function PasstoParse($targetid, $notification) { 
    $connection = new Connect();
    $connectinfo = $connection->GetConnection();
    $name = $connection->GetNamebyId($connectinfo, $targetid, 0);
    //echo '<p>Directed to: '.$name.' - '. $notification . '</p>';
}