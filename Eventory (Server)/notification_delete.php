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
if (array_key_exists('data', $_POST)) {
    $data = filter_input(INPUT_POST, 'data');
} else {
    $safe = false;
}
if ($safe) {
    $authenticated = $connection->Verify($connectinfo, $profid, $token);
    if ($authenticated) {
        $notificationarray = [];
        $row = $connection->GetRow($connectinfo, 1, $profid);
        $type = $type + 2;
        $current = $row[$type];
        $column = array_keys($row)[$type * 2];
        if ($current == null || $current == "") {
            
        } else {
            $currentarray = unserialize($current);
            $decrementcount = 0;
            $countarray = count($currentarray);
            $removeindex = [];
            $removestub = [];
            if (is_array($currentarray)) {
                if (isset($currentarray['isread'])) {
                    if ($currentarray['data'] == $data) {
                        if ($currentarray["isread"] == 0) {
                            $decrementcount++;
                        }
                        $currentarray = [];
                        $removeindex[] = 0;
                    }
                } else {
                    for ($i = 0; $i < count($currentarray); $i++) {
                        $loop = $currentarray[$i];
                        if ($loop['data'] == $data) {
                            if ($loop["isread"] == 0) {
                                $decrementcount++;
                            }
                            $removeindex[] = $i;
                        }
                    }
                    for ($j = 0; $j < count($removeindex); $j++) {
                        unset($currentarray[$removeindex[$j] - $j]);
                        $removestub[0] = ($countarray - 1) - $removeindex[$j];
                    }
                }
            }
            $currentarray = array_values($currentarray);
            if (count($currentarray) == 0) {
                $current = NULL;
            } else {
                $current = serialize($currentarray);
            }
            //Update Notif Comp
            $notifcomp = explode(";", $row["notification_raw"]);
            for ($j = 0; $j < count($removestub); $j++) {
                unset($notifcomp[$removestub[$j] - $j]);
            }
            if (count($notifcomp) == 0) {
                $notifstr = NULL;
            } else {
                $notifstr = implode(";", $notifcomp);
            }
            //Decrement Notification Count
            $unval = intval($currentrow["numberunseen"]) - $decrementcount;
            if ($unval < 0) {
                $unval = 0;
            }
        }
        $build = strval($connection->buildQuery(1, 1, $column)) . ' = :current, `notification_raw` = :notifstr, `numberunseen` = :unval WHERE id = :profid';
        $postsql = $connectinfo->prepare($build);
        $postsql->execute(array(':current' => $current, ':notifstr' => $notifstr, ':unval' => $unval,  ':profid' => $profid));
    } else {
        echo "Error - authorization mismatch";
    }
} else {
    echo 'Error - invalid supplied post data (not enough info?)';
}