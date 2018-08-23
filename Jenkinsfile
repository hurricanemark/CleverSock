node {
   agent {
      label 'AzureSLES-13.91.130.158'
      label 'IBM-LINUXONE-RHEL_kito'
   } 
   stage('Download Source Code') { // for display purposes
      // Get some code from a GitHub repository
      sh "curl -u markn:markn123 -O ftp://96.72.171.35/devrepo/CV4LINUX3_0/BUILDSRC-CV4LINUX3_0-SLES-x86_64.tar.gz;      tar -xvf BUILDSRC-CV4LINUX3_0-SLES-x86_64.tar.gz"
   }
   stage('Build') {
      // Run the maven build
      if (isUnix()) {
         sh "tar zxvf BUILDSRC-CV4LINUX3_0-SLES-x86_64.tar.gz"
         sh "cd CV4LINUX3_0; chmod +x build-cv4tcpipl.sh;  bash build-cv4tcpipl.sh"
      } else {
         echo "wrong os platform!!!"
      }
   }
   stage('Clean up') {
      sh "mv CV4LINUX3_0/OUTPUT OUTPUT; cd ..; rm -f BUILDSRC-CV4LINUX3_0-SLES-x86_64.tar.gz" 
   }
}
