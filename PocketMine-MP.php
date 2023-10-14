<?php
$descriptors = array(
    0 => array("pipe", "r"),
    1 => array("pipe", "w"),
    2 => array("pipe", "w") 
);

$process = proc_open('./start.sh', $descriptors, $pipes);

if (is_resource($process)) {
    stream_set_blocking($pipes[1], 0); 
    stream_set_blocking($pipes[2], 0); 

    while (!feof($pipes[1]) || !feof($pipes[2])) {
        $read = array($pipes[1], $pipes[2]);
        $write = null;
        $except = null;

        if (stream_select($read, $write, $except, null) > 0) {
            foreach ($read as $stream) {
                $output = fgets($stream);
                if ($output !== false) {
                    echo $output;
                }
            }
        }
    }

    fclose($pipes[0]);
    fclose($pipes[1]);
    fclose($pipes[2]);

    // 获取进程的返回值
    $returnValue = proc_close($process);

    echo "返回值：" . $returnValue;
}
?>
