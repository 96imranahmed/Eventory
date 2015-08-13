<?php
$safe = true;
include_once 'connect.php';
include_once 'notification_create.php';
$connection = new Connect();
$connectinfo = $connection->GetConnection();
if (array_key_exists('name', $_POST)) {
    $name = filter_input(INPUT_POST, 'name');
} else {
    $safe = false;
}
if (array_key_exists('id', $_POST)) {
    $idarray = filter_input(INPUT_POST, 'id', FILTER_DEFAULT, FILTER_REQUIRE_ARRAY);
    if (count($idarray) < 2) {
        $safe = false;
    } else {
        $idstring = implode(';', $idarray);
    }
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
if ($safe) {
    $authenticated = $connection->Verify($connectinfo, $profid, $token);
    if ($authenticated) {
        try {
            $starter = $idarray[0];
            $starterid= intval($starter);
            $prepsql = $connectinfo->prepare("INSERT INTO Groups (name, people_requested, people_accepted, starter) VALUES ('$name','$idstring', '$starter','$starterid')");
            $prepsql->execute();
            $groupid = $connectinfo->lastInsertId();
            echo $groupid;
            //Add group to thread starter's list of groups
            $connection->AddtoList($connectinfo, "Profiles", $starter, "groups_accepted", $groupid);
            //Notify users of new group
            array_shift($idarray); //Knock thread starter off!
            $added = array($starter=>$idarray);//Setup added list
            $addedstring = serialize($added);
            $postsql = $connectinfo->prepare("UPDATE Groups SET people_added = '$addedstring' WHERE id='$groupid'");
            $postsql->execute();
            foreach ($idarray as $id) {
                $params = ["groupid" => $groupid, "sourceid" => $profid, "date" => time()];
                //Add to notifications for that particular id
                CreateNotification(1, $connectinfo, $id, $starter, $groupid);
            }
        } catch (PDOException $e) {
            echo 'Error ' . $e->GetMessage();
        }
    } else {
        echo "Error - authorization mismatch";
    }
} else {
    echo 'Error - invalid supplied post data (not enough info?)';
}
