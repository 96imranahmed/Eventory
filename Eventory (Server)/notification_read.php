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
    //Possibly check if the name is correct - invited you to join x but x might be changed to y in that time!
    $authenticated = $connection->Verify($connectinfo, $profid, $token);
    if ($authenticated) {
        $notificationarray = [];
        $row = $connection->GetRow($connectinfo, "Notifications", $profid);
        for ($i = 2; $i < $count; $i++) {
            $name = array_keys($row)[$i * 2];
            print_r($name);
            $value = $row[$i];
            print_r($value);
            $current = $row[$name];
            if ($current == null || $current == "") {
                
            } else {
                $currentarray = unserialize($current);
                if (is_array($currentarray)) {
                    if ($currentarray["isread"] == null) {
                        for ($i = 0; $i < count($currentarray); $i++) {
                            $loop = $currentarray[$i];
                            $loop["isread"] = 1;
                            $currentarray[$i] = $loop;
                        }
                    } else {
                        $currentarray["isread"] = 1;
                    }
                }
                $current = serialize($currentarray);
                if (count($readstring) == 0) {
                    $readstring = ["$name = '$current'"];
                } else {
                    $readstring[] = "$name = '$current'";
                }
            }
        }
        print_r($readstring);
        //$postsql = $connectinfo->prepare("UPDATE Notifications SET $name='$current' WHERE id=$profid");
        //$postsql->execute();
    } else {
        echo "Error - authorization mismatch";
    }
} else {
    echo 'Error - invalid supplied post data (not enough info?)';
}