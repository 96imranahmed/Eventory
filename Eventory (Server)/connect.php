<?php

class Connect {

    public $dbo;

//Setups an initial connection
    public function GetConnection() {
        try {
            $ServerName = "localhost";
            $dbo = new PDO('mysql:host=' . $ServerName . ';dbname=' . $database, $username, $password);
            $dbo->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);
            $dbo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            return $dbo;
        } catch (PDOException $e) {
            return $e->getMessage();
        }
    }

    public function buildQuery($type, $querytype, $queryend = "") {
        switch ($type) {
            case 0;
                $table = "Groups";
                break;
            case 1;
                $table = "Notifications";
                break;
            case 2;
                $table = "Profiles";
                break;
        }
        switch ($querytype) {
            case 0;
                $sql = "SELECT * FROM `$table` ";
                break;
            case 1;
                $sql = "UPDATE `$table` SET `$queryend`";
                break;
        }
        return($sql);
    }

//Updates a list array with a new entry
    public function AddtoList($pdo, $tablename, $id, $column, $value) {
        $prepsql = $pdo->prepare($this->buildQuery($tablename, 0) . 'WHERE id = :id LIMIT 1');
        $prepsql->execute(array(':id' => $id));
        $currentrow = $prepsql->fetch();
        $current = $currentrow[$column];
        if ($current == null) {
            $current = $value;
        } else {
            if ($current == "") {
                $current = $value;
            } else {
                $currentarray = explode(";", $current);
                if (in_array($value, $currentarray)) {
                    
                } else {
                    $currentarray[] = $value;
                    $current = implode(";", $currentarray);
                }
            }
        }
        $postsql = $pdo->prepare($this->buildQuery($tablename, 1, $column) . ' = :current WHERE id = :id');
        $postsql->execute(array(':current' => $current, ':id' => $id));
    }

//Removes an entry from a list array
    public function RemovefromList($pdo, $tablename, $id, $column, $value) {
        $prepsql = $pdo->prepare($this->buildQuery($tablename, 0) . 'WHERE id = :id LIMIT 1');
        $prepsql->execute(array(':id' => $id));
        $currentrow = $prepsql->fetch();
        $current = $currentrow[$column];
        if ($current == null || $current == "") {
            $postsql = $pdo->prepare($this->buildQuery($tablename, 1, $column) . ' = null WHERE id = :id');
            $postsql->execute(array(':id' => $id));
        } else {
            $currentarray = explode(";", $current);
            if (($key = array_search($value, $currentarray)) !== false) {
                unset($currentarray[$key]);
            } else {
                
            }
            if (count($currentarray) < 1) {
                $current = null;
                $postsql = $pdo->prepare($this->buildQuery($tablename, 1, $column) . ' = null WHERE id = :id');
                $postsql->execute(array(':id' => $id));
            } else {
                $current = implode(';', $currentarray);
                $postsql = $pdo->prepare($this->buildQuery($tablename, 1, $column) . ' = :current WHERE id = :id');
                $postsql->execute(array(':current' => $current, ':id' => $id));
            }
        }
    }

//Checks if a value is in list
    public function ListCheck($pdo, $tablename, $id, $column, $value) {
        $prepsql = $pdo->prepare($this->buildQuery($tablename, 0) . 'WHERE id = :id LIMIT 1');
        $prepsql->execute(array(':id' => $id));
        $currentrow = $prepsql->fetch();
        $current = $currentrow[$column];
        if ($tablename == 1) {
            $checkarray = unserialize($current);
            if (is_array($checkarray)) {
                $check = false;
                foreach ($checkarray as $entry) {
                    if (strpos($entry['data'], strval($value)) !== false) {
                        $check = true;
                        break;
                    }
                }
                return $check;
            } else {
                return false;
            }
        } else {
            if ($current == null || $current == "") {
                if ($value == null || $value == "") {
                    return true;
                } else {
                    return false;
                }
            } else {
                $currentarray = explode(";", $current);
                if (($key = array_search($value, $currentarray)) !== false) {
                    return true;
                } else {
                    return false;
                }
            }
        }
    }

//Checks if supplied token matches values stored in database
    public function Verify($pdo, $id, $token) {
        $prepsql = $pdo->prepare("SELECT * FROM Profiles WHERE id = :id LIMIT 1");
        $prepsql->execute(array(':id' => $id));
        $currentrow = $prepsql->fetch();
        $current = preg_replace("/[^a-zA-Z0-9]+/", "", $currentrow["token"]);
        $token = preg_replace("/[^a-zA-Z0-9]+/", "", $token);
        if ($current == null || $current == "") {
            return false;
        } else {
            if (strcmp($token, $current) == 0) {
                return true;
            } else {
                return false;
            }
        }
    }

//Checks if initial supplied token is valid and if so returns True
    public function TokenVerify($id, $token) {
        $result = @file_get_contents("https://graph.facebook.com/me?access_token=$token");
        if (FALSE === $result) {
            return false;
        } else {

            if (strpos($result, $id) !== false) {
                return true;
            } else {
                return false;
            }
        }
    }

//Get the Name property for a given ID and type
    public function GetNamebyId($pdo, $id, $type) {
        if ($type == 0) {
            //Get name of a person
            $prepsql = $pdo->prepare("SELECT * FROM Profiles WHERE id = :id LIMIT 1");
            $prepsql->execute(array(':id' => $id));
            $currentrow = $prepsql->fetch();
            return($currentrow["name"]);
        } elseif ($type == 1) {
            //Get name of group
            $prepsql = $pdo->prepare("SELECT * FROM Groups WHERE id = :id LIMIT 1");
            $prepsql->execute(array(':id' => $id));
            $currentrow = $prepsql->fetch();
            return($currentrow["name"]);
        } else {
            return ("Error - invalid type request");
        }
    }

//Get the first ID of an entry
    public function GetFirstEntry($pdo, $tablename, $id, $column) {
        $prepsql = $pdo->prepare($this->buildQuery($tablename, 0) . 'WHERE id = :id LIMIT 1');
        $prepsql->execute(array(':id' => $id));
        $currentrow = $prepsql->fetch();
        $current = $currentrow[$column];
        if ($current == null || $current == "") {
            return null;
        } else {
            return explode(";", $current)[0];
        }
    }

//Get value at a certain point
    public function GetValue($pdo, $tablename, $id, $column) {
        $prepsql = $pdo->prepare($this->buildQuery($tablename, 0) . 'WHERE id = :id LIMIT 1');
        $prepsql->execute(array(':id' => $id));
        $currentrow = $prepsql->fetch();
        $current = $currentrow[$column];
        return $current;
    }

//Get row at a certain point
    public function GetRow($pdo, $tablename, $id) {
        $prepsql = $pdo->prepare($this->buildQuery($tablename, 0) . 'WHERE id = :id LIMIT 1');
        $prepsql->execute(array(':id' => $id));
        $currentrow = $prepsql->fetch();
        return $currentrow;
    }

    public function UpdateScore($pdo, $id, $change) {
        $prepsql = $pdo->prepare("SELECT * FROM Profiles WHERE id = :id LIMIT 1");
        $prepsql->execute(array(':id' => $id));
        $currentrow = $prepsql->fetch();
        $current = intval($currentrow["score"]) + intval($change);
        if ($current < 0) {
            $current = 0;
        }
        $postsql = $pdo->prepare("UPDATE Profiles SET score = :current WHERE id = :id");
        $postsql->execute(array(':current' => $current, ':id' => $id));
    }

    //Increments unseen notification count
    public function IncrementNotification($pdo, $id) {
        $prepsql = $pdo->prepare("SELECT * FROM Notifications WHERE id = :id LIMIT 1");
        $prepsql->execute(array(':id' => $id));
        $currentrow = $prepsql->fetch();
        $current = intval($currentrow["numberunseen"]) + 1;
        $postsql = $pdo->prepare("UPDATE Notifications SET numberunseen = :current WHERE id = :id");
        $postsql->execute(array(':current' => $current, ':id' => $id));
    }

    //Decrements unseen notification count
    public function DecrementNotification($pdo, $id) {
        $prepsql = $pdo->prepare("SELECT * FROM Notifications WHERE id = :id LIMIT 1");
        $prepsql->execute(array(':id' => $id));
        $currentrow = $prepsql->fetch();
        $current = intval($currentrow["numberunseen"]) - 1;
        if ($current < 0) {
            $current = 0;
        }
        $postsql = $pdo->prepare("UPDATE Notifications SET numberunseen = :current WHERE id = :id");
        $postsql->execute(array(':current' => $current, ':id' => $id));
    }

    public function DecrementNotificationCount($pdo, $id, $count) {
        $prepsql = $pdo->prepare("SELECT * FROM Notifications WHERE id = :id LIMIT 1");
        $prepsql->execute(array(':id' => $id));
        $currentrow = $prepsql->fetch();
        $current = intval($currentrow["numberunseen"]) - $count;
        if ($current < 0) {
            $current = 0;
        }
        $postsql = $pdo->prepare("UPDATE Notifications SET numberunseen = :current WHERE id = :id");
        $postsql->execute(array(':current' => $current, ':id' => $id));
    }

    //Add unique id to list
    public function AddItemtoList($pdo, $tablename, $id, $column, $value, $duplicateref) {
        $prepsql = $pdo->prepare($this->buildQuery($tablename, 0) . 'WHERE id = :id LIMIT 1');
        $prepsql->execute(array(':id' => $id));
        $currentrow = $prepsql->fetch();
        $current = $currentrow[$column];
        if ($current == null || $current == "") {
            $currentarray = [$value];
            $current = serialize($currentarray);
            if ($tablename == 1) {
                $this->IncrementNotification($pdo, $id);
            }
        } else {
            $currentarray = unserialize($current);
            $unique = true;
            for ($i = 0; $i < count($currentarray); $i++) {
                $loop = $currentarray[$i];
                if ($loop[$duplicateref] == $value[$duplicateref]) {
                    $unique = false;
                }
            }
            if ($unique) {
                $currentarray[] = $value;
                if ($tablename == 1) {
                    $this->IncrementNotification($pdo, $id);
                }
            }
            $current = serialize($currentarray);
        }
        $postsql = $pdo->prepare($this->buildQuery($tablename, 1, $column) . ' = :current WHERE id = :id');
        $postsql->execute(array(':current' => $current, ':id' => $id));
    }

    //Add item to a list - ignoring possibility of a duplicate
    public function AddNewtoList($pdo, $tablename, $id, $column, $value) {
        $prepsql = $pdo->prepare($this->buildQuery($tablename, 0) . 'WHERE id = :id LIMIT 1');
        $prepsql->execute(array(':id' => $id));
        $currentrow = $prepsql->fetch();
        $current = $currentrow[$column];
        if ($current == null) {
            $current = $value;
        } else {
            if ($current == "") {
                $current = $value;
            } else {
                $currentarray = explode(";", $current);
                $currentarray[] = $value;
                $current = implode(";", $currentarray);
            }
        }
        $postsql = $pdo->prepare($this->buildQuery($tablename, 1, $column) . ' = :current WHERE id = :id');
        $postsql->execute(array(':current' => $current, ':id' => $id));
    }

    //Remove item from list
    public function RemoveItemfromList($pdo, $tablename, $id, $column, $item, $duplicateref) {
        $prepsql = $pdo->prepare($this->buildQuery($tablename, 0) . 'WHERE id = :id LIMIT 1');
        $prepsql->execute(array(':id' => $id));
        $currentrow = $prepsql->fetch();
        $current = $currentrow[$column];
        $decrementcount = 0;
        if ($current == null || $current == "") {
            $postsql = $pdo->prepare($this->buildQuery($tablename, 1, $column) . ' = null WHERE id = :id');
            $postsql->execute(array(':id' => $id));
        } else {
            $currentarray = unserialize($current);
            $removeindex = [];
            for ($i = 0; $i < count($currentarray); $i++) {
                $check = $currentarray[$i];
                if ($item == $check[$duplicateref]) {
                    $removeindex[] = $i;
                    if ($check["isread"] == 0) {
                        $decrementcount++;
                    }
                }
            }
            for ($j = 0; $j < count($removeindex); $j++) {
                unset($currentarray[$removeindex[$j] - $j]);
            }
            if (is_array($currentarray)) {
                $currentarray = array_merge($currentarray);
            }
            if ($tablename == 1) {
                $this->DecrementNotificationCount($pdo, $id, $decrementcount);
                $notifraw = $this->GetValue($pdo, 1, $id, "notification_raw");
                $notiflist = explode(";", $notifraw);
                $columnid = array_search($column, array_keys($currentrow));
                $notifremove = [];
                $occurencecount = 0;
                //NEED TO REMOVE FROM RAW AS WELL!
                for ($b = 0; $b < count($notiflist); $b++) {
                    if ($notiflist[$b] == $columnid) {
                      if (in_array($occurencecount, $removeindex)) {
                          $notifremove[] = $b;
                      }
                      $occurencecount++;
                    }
                }
                for ($a = 0; $a < count($notifremove); $a++) {
                    unset($notiflist[$notifremove[$a] - $a]);
                }
                if (count($notiflist) == 0) {
                    $notifstring = NULL;
                } else {
                    $notifstring = implode(";", $notiflist);                   
                }
                $notifsql = $pdo->prepare('UPDATE Notifications SET notification_raw = :notifstring WHERE id = :id');
                $notifsql->execute(array(':notifstring' => $notifstring, ':id' => $id));
            }
            if (!is_array($currentarray)) {
                $current = null;
                $postsql = $pdo->prepare($this->buildQuery($tablename, 1, $column) . ' = null WHERE id = :id');
                $postsql->execute(array(':id' => $id));
            } else {
                if (count($currentarray) < 1) {
                    $current = null;
                    $postsql = $pdo->prepare($this->buildQuery($tablename, 1, $column) . ' = null WHERE id = :id');
                    $postsql->execute(array(':id' => $id));
                } else {
                    $current = serialize($currentarray);
                    $postsql = $pdo->prepare($this->buildQuery($tablename, 1, $column) . ' = :current WHERE id = :id');
                    $postsql->execute(array(':current' => $current, ':id' => $id));
                }
            }
        }
    }

    //Set read receipt
    public function SetRead($pdo, $id, $column) {
        $prepsql = $pdo->prepare("SELECT * FROM Notifications WHERE id = :id LIMIT 1");
        $prepsql->execute(array(':id' => $id));
        $currentrow = $prepsql->fetch();
        $current = $currentrow[$column];
        if ($current == null || $current == "") {
            $postsql = $pdo->prepare($this->buildQuery(1, 1, $column) . ' = null WHERE id = :id');
            $postsql->execute(array(':id' => $id));
        } else {
            $currentarray = unserialize($current);
            if (is_array($currentarray)) {
                if (isset($currentarray['isread'])) {
                    if ($currentarray["isread"] == 0) {
                        $currentarray["isread"] = 1;
                        $this->DecrementNotification($pdo, $id);
                    }
                } else {
                    for ($i = 0; $i < count($currentarray); $i++) {
                        $loop = $currentarray[i];
                        if ($loop["isread"] == 0) {
                            $loop["isread"] = 1;
                            $this->DecrementNotification($pdo, $id);
                        }
                        $currentarray[i] = $loop;
                    }
                }
            }
            $current = serialize($currentarray);
            $postsql = $pdo->prepare($this->buildQuery(1, 1, $column) . ' = :current WHERE id = :id');
            $postsql->execute(array(':current' => $current, ':id' => $id));
        }
    }

}
