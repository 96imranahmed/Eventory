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
        $count = intval(count($row)) / 2;
        for ($i = 2; $i < $count; $i++) {
            $name = array_keys($row)[2 * $i + 1];
            $value = $row[$name];
            if ($value == null || $value == "") {
                
            } else {
                if (count($notificationarray) == 0) {
                    $add = unserialize($value);
                    if (is_array($add)) {
                        if ($add["isread"] == nil) {
                            //Must be collection of items
                            $notificationarray = $add;
                        } else {
                            $notificationarray = [unserialize($value)];
                        }
                    }
                } else {
                    $add = unserialize($value);
                    if (is_array($add)) {
                        if ($add["isread"] == nil) {
                            //Must be collection of items
                            for ($i = 0; $i < count($add); $i++) {
                                $notificationarray[] = $add[i];
                            }
                        } else {
                            $notificationarray[] = unserialize($add);
                        }
                    }
                }
                $prepsql = $connectinfo->prepare("SELECT * FROM Notifications WHERE id = '$profid' LIMIT 1");
                $prepsql->execute();
                $currentrow = $prepsql->fetch();
                $current = $currentrow[$name];
                if ($current == null || $current == "") {
                    $postsql = $connectinfo->prepare("UPDATE Notifications SET $name = null WHERE id=$profid");
                    $postsql->execute();
                } else {
                    var_dump($current);
                    $currentarray = unserialize($current);
                    var_dump($currentarray);
                    if (is_array($currentarray)) {
                        echo("Is Array    ");
                        if ($currentarray["isread"] == null) {
                            echo("Is null    ");
                            for ($i = 0; $i < count($currentarray); $i++) {
                                $loop = $currentarray[i];
                                $loop["isread"] = 1;
                                $currentarray[i] = $loop;
                            }
                        } else {
                            $currentarray["isread"] = 1;
                        }
                    } else {
                        echo("Is not array");
                    }
                    //echo($current);
                    $current = serialize($currentarray);
                    //$postsql = $connectinfo->prepare("UPDATE Notifications SET $name='$current' WHERE id=$profid");
                    //$postsql->execute();
                }
            }
        }
        echo json_encode($notificationarray);
    } else {
        echo "Error - authorization mismatch";
    }
} else {
    echo 'Error - invalid supplied post data (not enough info?)';
}