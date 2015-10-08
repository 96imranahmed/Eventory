<?php

function sortbydate($a, $b) {
    return $a["date"] - $b["date"];
}

function checktext($connection, $pdo, $inputnotif) {
    if ($inputnotif['type'] == 1 || $inputnotif['type'] == 2) {
        $idcheck = substr($inputnotif['data'], 8, strlen($inputnotif['data']) - 8);
        $groupname = $connection->GetNamebyId($pdo, $idcheck, 1);
        $inputnotif['text'] = $inputnotif['text'] . $groupname;
    }
    return $inputnotif;
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
        $notificationskeleton = [];
        $compareskeleton = [];
        $row = $connection->GetRow($connectinfo, 1, $profid);
        $notifcomp = explode(";", $row["notification_raw"]);
        if ($haslimit && $safelimit) {
            $limit = $limitnumber * ($limitpage + 1);
            $notifcomp = array_reverse($notifcomp);
            $startcount = count($notifcomp);
            $skeletonraw = array_splice($notifcomp, -$limit);
            if (($startcount - $limit + $limitnumber) <= 0) {
                $skeletonraw = [];
            }
            for ($j = 0; $j < count($skeletonraw); $j++) {
                if ($j < $limitnumber && $j < (count($skeletonraw) - $limitnumber * $limitpage)) {
                    if (in_array($skeletonraw[$j] + 2, array_keys($notificationskeleton))) {
                        $replace = $notificationskeleton[$skeletonraw[$j] + 2];
                        $replace++;
                        $notificationskeleton[$skeletonraw[$j] + 2] = $replace;
                    } else {
                        $notificationskeleton[$skeletonraw[$j] + 2] = 1;
                    }
                } else {
                    if (in_array($skeletonraw[$j] + 2, array_keys($compareskeleton))) {
                        $replace = $compareskeleton[$skeletonraw[$j] + 2];
                        $replace++;
                        $compareskeleton[$skeletonraw[$j] + 2] = $replace;
                    } else {
                        $compareskeleton[$skeletonraw[$j] + 2] = 1;
                    }
                }
            }
            //^^ Ensures only the right number of notifications are copied
            $count = intval(count($row))/2;
            $readstring = [];
            for ($i = 3; $i < $count; $i++) {
                $verify = $i;
                //$name = array_keys($row)[$i * 2];
                $value = $row[$i];
                if ($value == null || $value == "") {
                    
                } else {
                    $add = unserialize($value);
                    if (is_array($add)) {
                        if (isset($add['isread'])) {
                            if ($compareskeleton[$verify] > 0) {
                                
                            } else {
                                if ($notificationskeleton[$verify] > 0) {
                                    $notificationarray[] = checktext($connection, $connectinfo, $add[0]);
                                }
                            }
                        } else {
                            //Must be collection of items
                            if (isset($compareskeleton[$verify])){
                                $min = $compareskeleton[$verify];
                                if (isset($notificationskeleton[$verify])){
                                $max = $notificationskeleton[$verify] + $compareskeleton[$verify];
                                } else {
                                $max = $min;
                                }
                            } else {
                                $min = 0;
                                if (isset($notificationskeleton[$verify])){
                                $max = $notificationskeleton[$verify];
                                } else {
                                $max = 0;
                                }
                            }
                            for ($t = $min; $t < $max; $t++) {
                                $notificationarray[] = checktext($connection, $connectinfo, $add[$t]);
                            }
                        }
                    }
                }
            }
        } else {
            $count = intval(count($row)) / 2;
            $readstring = [];
            for ($i = 3; $i < $count; $i++) {
                //$name = array_keys($row)[$i * 2];
                $value = $row[$i];
                if ($value == null || $value == "") {
                    
                } else {
                    $add = unserialize($value);
                    if (is_array($add)) {
                        if (isset($add['isread'])) {
                            $notificationarray[] = checktext($connection, $connectinfo, $add[0]);
                        } else {
                            //Must be collection of items
                            for ($t = 0; $t < count($add); $t++) {
                                $notificationarray[] = checktext($connection, $connectinfo, $add[$t]);
                            }
                        }
                    }
                }
            }
        }
        usort($notificationarray, "sortbydate");
        array_unshift($notificationarray, ["numberunseen" => $row["numberunseen"]]);
        echo json_encode($notificationarray);
    } else {
        echo "Error - authorization mismatch";
    }
} else {
    echo 'Error - invalid supplied post data (not enough info?)';
}
