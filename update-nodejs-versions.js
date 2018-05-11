#! /usr/bin/env node

const fs = require('fs')

console.log('Updating Node.js versions')

const versions = [
  '8.7.0',
  '8.8.0',
  '8.8.1',
  '8.9.0',
  '8.9.1',
  '8.9.2',
  '8.9.3',
  '8.9.4',
  '8.10.0',
  '8.11.0',
  '8.11.1',
  '9.0.0',
  '9.1.0',
  '9.2.0',
  '9.2.1',
  '9.3.0',
  '9.4.0',
  '9.5.0',
  '9.6.0',
  '9.6.1',
  '9.7.0',
  '9.7.1',
  '9.8.0',
  '9.9.0',
  '9.10.0',
  '9.10.1',
  '9.11.0',
  '9.11.1',
  '10.0.0',
  '10.1.0'
]

const getVersionXML = (version) => {
  return `    <jenkins.plugins.nodejs.tools.NodeJSInstallation>
      <name>${version}</name>
      <properties>
        <hudson.tools.InstallSourceProperty>
          <installers>
            <jenkins.plugins.nodejs.tools.NodeJSInstaller>
              <id>${version}</id>
              <npmPackagesRefreshHours>72</npmPackagesRefreshHours>
            </jenkins.plugins.nodejs.tools.NodeJSInstaller>
          </installers>
        </hudson.tools.InstallSourceProperty>
      </properties>
    </jenkins.plugins.nodejs.tools.NodeJSInstallation>
`
}

const fileHeader = `<?xml version='1.0' encoding='UTF-8'?>
<jenkins.plugins.nodejs.tools.NodeJSInstallation_-DescriptorImpl plugin="nodejs@1.2.4">
  <installations class="jenkins.plugins.nodejs.tools.NodeJSInstallation-array">
`
const fileFooter = `  </installations>
</jenkins.plugins.nodejs.tools.NodeJSInstallation_-DescriptorImpl>`

let finalFile = ''
finalFile = finalFile + fileHeader
versions.forEach((version) => {
  finalFile = finalFile + getVersionXML(version)
})
finalFile = finalFile + fileFooter

fs.writeFileSync('./config/jenkins.plugins.nodejs.tools.NodeJSInstallation.xml', finalFile)

console.log('Wrote Node.js versions to ./config/jenkins.plugins.nodejs.tools.NodeJSInstallation.xml')
