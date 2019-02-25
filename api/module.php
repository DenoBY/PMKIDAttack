<?php
/**
 * User: n3d.b0y
 * Email: n3d.b0y@gmail.com
 */

namespace pineapple;

class PMKIDAttack extends Module
{
    const PATH_MODULE = '/pineapple/modules/PMKIDAttack';

    public function route()
    {
        switch ($this->request->action) {
            case 'isConnected':
                $this->isConnected();
                break;
            case 'wipeLog':
                $this->wipeLog();
                break;
            case 'getLog':
                $this->getLog();
                break;
            case 'getInfo':
                $this->getInfo();
                break;
            case 'getDependenciesStatus':
                $this->getDependenciesStatus();
                break;
            case 'forceManagerDependencies':
                $this->forceManagerDependencies();
                break;
            case 'managerDependencies':
                $this->managerDependencies();
                break;
            case 'statusDependencies':
                $this->statusDependencies();
                break;
            case 'startAttack':
                $this->startAttack();
                break;
            case 'stopAttack':
                $this->stopAttack();
                break;
            case 'catchPMKID':
                $this->catchPMKID();
                break;
            case 'getPMKIDFiles':
                $this->getPMKIDFiles();
                break;
            case 'downloadPMKID':
                $this->downloadPMKID();
                break;
            case 'deletePMKID':
                $this->deletePMKID();
                break;
            case 'getOutput':
                $this->getOutput();
                break;
            case 'getStatusAttack':
                $this->getStatusAttack();
                break;
        }
    }

    public function isConnected()
    {
        $connected = @fsockopen("google.com", 80);

        if ($connected) {
            $this->response = array('success' => true);
        } else {
            $this->response = array('success' => false);
        }
    }

    private function wipeLog()
    {
        if (!file_exists('/var/log/pmkidattack.log')) {
            touch('/var/log/pmkidattack.log');
        }

	exec("rm /var/log/pmkidattack.log");

	touch('/var/log/pmkidattack.log');
    }
    
    private function getLog()
    {
        if (!file_exists('/var/log/pmkidattack.log')) {
            touch('/var/log/pmkidattack.log');
        }

        $file = file_get_contents('/var/log/pmkidattack.log');
       
        $this->response = array("pmkidlog" => $file);
    }

    private function getDependenciesStatus()
    {
        if (!file_exists('/tmp/PMKIDAttack.progress')) {
            if ($this->checkDependency()) {
                $this->response = array(
                    "installed" => false, "install" => "Remove",
                    "installLabel" => "danger", "processing" => false
                );
            } else {
                $this->response = array(
                    "installed" => true, "install" => "Install",
                    "installLabel" => "success", "processing" => false
                );
            }
        } else {
            $this->response = array(
                "installed" => false, "install" => "Installing...",
                "installLabel" => "warning", "processing" => true
            );
        }
    }

    protected function checkDependency()
    {
        return ((trim(exec("which hcxdumptool")) == '' ? false : true) && $this->uciGet("pmkidattack.module.installed"));
    }

    private function forceManagerDependencies()
    {
        if (!$this->checkDependency()) {
            $this->execBackground(self::PATH_MODULE . "/scripts/dependencies.sh force install");
            $this->response = array('success' => true);
        } else {
            $this->execBackground(self::PATH_MODULE . "/scripts/dependencies.sh force remove");
            $this->response = array('success' => true);
        }
    }

    private function managerDependencies()
    {
        if (!$this->checkDependency()) {
            $this->execBackground(self::PATH_MODULE . "/scripts/dependencies.sh install");
            $this->response = array('success' => true);
        } else {
            $this->execBackground(self::PATH_MODULE . "/scripts/dependencies.sh remove");
            $this->response = array('success' => true);
        }
    }

    private function statusDependencies()
    {
        if (!file_exists('/tmp/HandshakeCrack.progress')) {
            $this->response = array('success' => true);
        } else {
            $this->response = array('success' => false);
        }
    }

    private function startAttack()
    {
        $this->uciSet('pmkidattack.attack.bssid', $this->request->bssid);

        $this->uciSet('pmkidattack.attack.run', '1');
        exec("echo " . $this->getFormatBSSID() . " > " . self::PATH_MODULE . "/filter.txt");
        exec(self::PATH_MODULE . "/scripts/PMKIDAttack.sh start " . $this->getFormatBSSID());
        $this->response = array('success' => true);
    }

    private function stopAttack()
    {
        $this->uciSet('pmkidattack.attack.run', '0');

        exec("pkill hcxdumptool");

        if ($this->checkPMKID()) {
            exec('cp /tmp/' . $this->getFormatBSSID() . '.pcapng ' . self::PATH_MODULE . '/pcapng/');
        }

        exec("rm -rf /tmp/" . $this->getFormatBSSID() . '.pcapng');
        exec("rm -rf " . self::PATH_MODULE . "/log/output.txt");

        $this->response = array('success' => true);
    }


    private function catchPMKID()
    {
        if ($this->checkPMKID()) {
            $this->response = array('success' => true);
        } else {
            $this->response = array('success' => false);
        }
    }

    private function getFormatBSSID()
    {
        $bssid = $this->uciGet('pmkidattack.attack.bssid');
        $bssidFormat = str_replace(':', '', $bssid);

        return $bssidFormat;
    }

    private function checkPMKID()
    {
        $searchLine = 'PMKIDs';

        exec('hcxpcaptool -z /tmp/pmkid.txt /tmp/' . $this->getFormatBSSID() . '.pcapng  &> ' . self::PATH_MODULE . '/log/output.txt');
        $file = file_get_contents(self::PATH_MODULE . '/log/output.txt');
        exec('rm -r /tmp/pmkid.txt');

        return strpos($file, $searchLine) !== false;
    }

    private function getPMKIDFiles()
    {
        $pmkids = [];
        exec("find -L " . self::PATH_MODULE . "/pcapng/ -type f -name \"*.**pcapng\" 2>&1", $files);

        if (strpos($files[0], 'find') !== false) {
            $pmkids = [];
        } else {
            foreach ($files as $file) {
                array_push($pmkids,[
                    'path' => $file,
                    'name' => implode(str_split(basename($file, '.pcapng'), 2), ":")
                ]);
            }
        }

        $this->response = array("pmkids" => $pmkids);
    }

    private function downloadPMKID()
    {
        $fileName = basename($this->request->file, '.pcapng');

        exec("mkdir /tmp/PMKIDAttack/");
        exec("cp " . $this->request->file . " /tmp/PMKIDAttack/");
        exec('hcxpcaptool -z /tmp/PMKIDAttack/pmkid.16800 ' . $this->request->file . ' &> ' . self::PATH_MODULE . '/log/output3.txt');
        exec('rm -r ' . self::PATH_MODULE . '/log/output3.txt');
        exec("cd /tmp/PMKIDAttack/ && tar -czf /tmp/". $fileName .".tar.gz *");
        exec("rm -rf /tmp/PMKIDAttack/");
        $this->response = array("download" => $this->downloadFile("/tmp/". $fileName .".tar.gz"));
    }

    private function deletePMKID()
    {
        exec("rm -rf " . $this->request->file);
    }

    private function getOutput()
    {
        if (!empty($this->request->pathPMKID)) {
            exec('hcxpcaptool -z /tmp/pmkid.txt ' . $this->request->pathPMKID . ' &> ' . self::PATH_MODULE . '/log/output2.txt');
            $output = file_get_contents(self::PATH_MODULE . '/log/output2.txt');
            exec("rm -rf " . self::PATH_MODULE . "/log/output2.txt");
        } else {
            $output = file_get_contents(self::PATH_MODULE . '/log/output.txt');
        }

        $this->response = array("output" => $output);
    }

    private function getStatusAttack()
    {
        if ($this->uciGet('pmkidattack.attack.run') == '1') {
            $this->response = array('success' => true);
        } else {
            $this->response = array('success' => false);
        }
    }
}
