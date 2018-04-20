// Script to run on startup of jenkins
// Sets: github auth, immutablejenkins auth token, github webhook secret
// Run:
// export USERNAME=immutablejenkins
// export PASSWORD=$(cat /tmp/userauthtoken)
// TOKEN=$(curl --user "$USERNAME:$PASSWORD" -s http://localhost:8080/crumbIssuer/api/json | python -c 'import sys,json;j=json.load(sys.stdin);print j["crumbRequestField"] + "=" + j["crumb"]')
// curl --user "$USERNAME:$PASSWORD" -d "$TOKEN" --data-urlencode "script=$(<./init.groovy.d/01-set-github-auth.groovy)" http://localhost:8080/scriptText
import jenkins.model.Jenkins
import hudson.security.SecurityRealm
import hudson.util.Secret
import org.jenkinsci.plugins.GithubSecurityRealm
import com.cloudbees.plugins.credentials.impl.*;
import com.cloudbees.plugins.credentials.*;
import com.cloudbees.plugins.credentials.domains.*;
import org.jenkinsci.plugins.plaincredentials.impl.*;

String githubWebUri = 'https://github.com'
String githubApiUri = 'https://api.github.com'
String oauthScopes = 'read:org,user:email'

String clientIDPath = '/tmp/clientid'
String clientSecretPath = '/tmp/clientsecret'
String userAuthTokenPath = '/tmp/userauthtoken'
String webhookSecretPath = '/tmp/githubwebhooksecret'

System.out.println "--> Getting Credentials"
assert new File(clientIDPath): "Client ID not found"
assert new File(clientSecretPath): "Client Secret not found"
assert new File(userAuthTokenPath): "User Auth Token not found"
assert new File(webhookSecretPath): "Webhook Secret not find"

System.out.println "--> Deleting Credentials"
Boolean noSecrets = false
def String clientID
def String clientSecret
def String userAuthToken
def Secret webhookSecret
try {
    clientID = new File(clientIDPath).text
    clientSecret = new File(clientSecretPath).text
    userAuthToken = new File(userAuthTokenPath).text
    webhookSecret = Secret.fromString(new File(webhookSecretPath).text)
} catch (Exception err) {
    System.out.println(err)
    noSecrets = true
}

if (noSecrets) {
    System.out.println("--> All credentials already setup")
    return
}

// assert new File(clientIDPath).delete() : "Could not delete Client ID"
// assert new File(clientSecretPath).delete() : "Could not delete Client Secret"
// assert new File(userAuthTokenPath).delete() : "Could not delete User Auth Token"
// assert new File(webhookSecretPath).delete() : "Could not delete Webhook Secret"

System.out.println "--> Saving Github Credentials"
try {
    SecurityRealm github_realm = new GithubSecurityRealm(
            githubWebUri, githubApiUri, clientID, clientSecret, oauthScopes
    )

//check for equality, no need to modify the runtime if no settings changed
    if (!github_realm.equals(Jenkins.instance.getSecurityRealm())) {
        Jenkins.instance.setSecurityRealm(github_realm)
        Jenkins.instance.save()
    }
} catch (Exception err) {
    System.out.println(err)
    System.out.println("Tried setting Github secrets but either already done and we couldnt")
}

System.out.println "--> Creating ImmutableJenkins user"
try {
    Credentials c = (Credentials) new UsernamePasswordCredentialsImpl(
            CredentialsScope.GLOBAL,
            'immutablejenkins',
            'ImmutableJenkins Github login with auth token',
            'immutablejenkins',
            userAuthToken
    )
    assert SystemCredentialsProvider.getInstance().getStore().addCredentials(Domain.global(), c): "Could not add ImmutableJenkins credentials"
} catch (Exception err) {
    System.out.println(err)
    System.out.println("Tried creating ImmutableJenkins but couldn't")
}

System.out.println "--> Creating Github Webhook Secret"
try {
    Credentials c = (Credentials) new StringCredentialsImpl(
            CredentialsScope.GLOBAL,
            'github-webhook-secret',
            'Secret for accepting Github Webhooks',
            webhookSecret,
    )
    assert SystemCredentialsProvider.getInstance().getStore().addCredentials(Domain.global(), c): "Could not add secret for Github Webhook"
} catch (Exception err) {
    System.out.println(err)
    System.out.println("Tried setting Webhook Secret but either already done and we couldnt")
}
System.out.println("--> Initial setup done")

