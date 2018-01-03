- Secrets in jenkins
  - files/git diffs VS environment variables
    - use environment variables instead of files

- Review PR

- Secrets in jobs
  - websites will run on a trusted worker
  - needs to have hash, domain and domain token
  - domain token can be file/environment variable on trusted worker
  - victor will make sure ci/Jenkinsfile can not be altered to run
    steps outside of ipfs/jenkins-libs

- Terraform monorepo VS multiple repos for IPFS infra

- ipfs websites - how to pick a worker, how to grab an ipfs hash and pass it on to the next build step
