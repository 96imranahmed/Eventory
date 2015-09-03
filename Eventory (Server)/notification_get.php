<?php

function sortbydate($a, $b) {
    return $a["date"] - $b["date"];
}

$safe = true;
$safelimit = true;
$haslimit = true;
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
if (array_key_exists('limit', $_POST)) {
    $limitnumber = filter_input(INPUT_POST, 'limit');
} else {
    $haslimit = false;
}
if (array_key_exists('page', $_POST)) {
    $limitpage = filter_input(INPUT_POST, 'page');
} else {
    $safelimit = false;
}
if ($safe) {
    //Possibly check if the name is correct - invited you to join x but x might be changed to y in that time!
    $authenticated = $connection->Verify($connectinfo, $profid, $token);
    if ($authenticated) {
        $notificationarray = [];
        $row = $connection->GetRow($connectinfo, "Notifications", $profid);
        $count = intval(count($row)) / 2;
        $readstring = [];
        for ($i = 2; $i < $count; $i++) {
            $name = array_keys($row)[$i * 2];
            $value = $row[$i];
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
                            $notificationarray[] = ($add);
                        }
                    }
                }
            }
        }
        usort($notificationarray, "sortbydate");
        if ($haslimit) {
            if ($safelimit) {
                try {
                    $limitstart = $limitnumber * $limitpage;
                    $output = array_slice($notificationarray[0], $limitstart, $limitnumber, true);
                    $sendout = [$output];
                    array_unshift($output, ["numberunseen" => $row["numberunseen"]]);
                    echo json_encode($output);
                } catch (Exception $e) {
                    array_unshift($notificationarray, ["numberunseen" => $row["numberunseen"]]);
                    echo json_encode($notificationarray);
                }
            } else {
                array_unshift($notificationarray, ["numberunseen" => $row["numberunseen"]]);
                echo json_encode($notificationarray);
            }
        } else {
            array_unshift($notificationarray, ["numberunseen" => $row["numberunseen"]]);
            echo json_encode($notificationarray);
        }
    } else {
        echo "Error - authorization mismatch";
    }
} else {
    echo 'Error - invalid supplied post data (not enough info?)';
}
