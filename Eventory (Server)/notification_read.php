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
            if (is_array($currentarray)) {
                if (isset($currentarray['isread'])) {
                    if ($currentarray['data'] == $data) {
                        $currentarray["isread"] = 1;
                        $decrementcount++;
                    }
                } else {
                    for ($i = 0; $i < count($currentarray); $i++) {
                        $loop = $currentarray[$i];
                        if ($loop['data'] == $data) {
                            $loop["isread"] = 1;
                            $currentarray[$i] = $loop;
                            $decrementcount++;
                        }
                    }
                }
            }
            $current = serialize($currentarray);
        }
        $build = strval($connection->buildQuery(1, 1, $column)) . ' = :current WHERE id = :profid';
        $postsql = $connectinfo->prepare($build);
        $postsql->execute(array(':current' => $current, ":profid"=>$profid));
        $connection->DecrementNotificationCount($connectinfo, $profid, $decrementcount);
    } else {
        echo "Error - authorization mismatch";
    }
} else {
    echo 'Error - invalid supplied post data (not enough info?)';
}