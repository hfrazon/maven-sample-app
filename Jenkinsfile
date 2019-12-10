pipeline {
  options {
    gitLabConnection('jx-gitlab')
  }  
  agent {
    label "jenkins-maven"
  }
  environment {
    ORG = 'sfb-cicd'
    APP_NAME = 'gs-serving-web-content'
    CHARTMUSEUM_CREDS = credentials('jenkins-x-chartmuseum')
  }
  stages {
    stage('Construcao dos artefatos de Producao - CI') {
      when {
        tag '*-stable'
      }
      steps {
        container('maven') {
          // Carrega credenciais do git
          sh "git config --global credential.helper store"
          sh "jx step git credentials"
          // Tratamento das versoes dos artefatos
          //script { VERSION = sh(returnStdout: true, script: 'git tag -l --points-at HEAD').trim() }
          sh "echo \$(git describe --abbrev=0 --tags \$(git rev-list --tags --skip=0 --max-count=1)) > VERSION"
          //sh "echo $VERSION > VERSION"
          sh "echo $DOCKER_REGISTRY"
	  //-------------------------------------------------------------------------------------------------------------------
          // Sessao dedicada a construcao da aplicacao e prepracao para criacao de imagem Docker
          sh "mvn clean install"
          sh "mv target/gs-serving-web-content-0.1.0.jar target/gs-serving-web-content.jar"    
		  //-------------------------------------------------------------------------------------------------------------------      
          // Cria imagem Docker com Skaffold (com a nova tag)
          sh "export VERSION=`cat VERSION` && skaffold build -f skaffold.yaml"
          // Faz checagem da imagem
          sh "jx step post build --image $DOCKER_REGISTRY/$ORG/$APP_NAME:\$(cat VERSION)"          
        } 
      }
    }
    stage('Promove para ambiente de Producao') {
      when {
        tag '*-stable'
      }
      steps {
        container('maven') {
          dir("charts/gs-serving-web-content") {
            // Gera changelog
            sh "make tag"
            sh "jx step changelog --version \$(cat ../../VERSION)"
            // Versiona e armazena o Helm Chart no repositorio de Charts (Chartmuseum)
            sh "jx step helm release"
            // Faz a promocao para o ambiente
            sh "jx promote -b --no-poll=true --no-wait=true --env gs-serving-web-content --timeout 1h --version \$(cat ../../VERSION)"
          }
        }
      }
    }      
  }
  post {
       failure {
         updateGitlabCommitStatus name: "build${env.BUILD_NUMBER}", state: 'failed'
       }
       success {
         updateGitlabCommitStatus name: "build${env.BUILD_NUMBER}", state: 'success'
       }    
       always {
         cleanWs()
       }
  }
}


