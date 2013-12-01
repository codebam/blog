---
title: Backing Up Sensitive Data With Secret Sharing
author: Alex Beal
date: 02-24-2013
type: post
permalink: secret-sharing-backup
---

Backing up sensitive data can be problematic, as the process of making something redundant increases the risk of it being misplaced or stolen. Encryption can solve this problem, as a stolen backup isn't useful if it's encrypted. The issue, though, is that it only pushes the problem back a step. Now there's an additional piece of information, the encryption key, that needs to be backed up which faces the same issue. Making the key redundant decreases the chance of losing the key, but increases the chance of having it stolen. The key itself is now the piece of sensitive data that needs to be backed up.

One solution to this is secret sharing. What is secret sharing? It's a way of splitting a secret (like an encryption key) into multiple parts. Under a secret sharing scheme, there's a threshold, *t*, and a shares count, *n*. The scheme takes a secret and splits it into *n* parts. The secret can then be recreated by combining at least *t* of the parts (known as *shares*). Less than *t* shares is useless, and cannot be used to recreate the secret. Intuitively, if *n*=10 and *t*=3, then this is like a safe with three keyholes and ten keys, which cannot be opened unless three of the ten keys are applied at the same time. ^[Intuitively, the way this works is by thinking about the space of possible secrets as a 3D space, where each point is a possible secret. You can then think of each share as a plane going through this space. If *n* is ten, then ten planes which intersect the secret point are generated. Only three or more planes are needed to uniquely find the secret point. Less than three will only identify a plane or line of points.]

This technique has many uses, one of which is making sensitive data redundant. First let's return to the backup scheme without secret sharing. Under this scheme, the data is encrypted and spread across multiple system. The encryption key itself is then also spread across multiple (hopefully different) systems. The issue, of course, is that if even one of the systems storing the key is compromised, the data could potentially be compromised. Now contrast this with a backup system using secret sharing. Here, the data is also encrypted and spread around, but the difference is that rather than spreading the key, the key is split, and the shares are spread around. If the key needs to be backed up to *n* different systems, then *n* shares are created, and each system stores one share. The difference is that now at least *t* of those systems must be compromised before the data is in danger, rather than just one. Additionally, *n*-*t* of those systems can fail without the secret being lost.

## Mathematical Modeling
Inevitably, secret sharing still pulls in two different directions. Increasing *t* makes it harder to steal the secret, as at least *t* systems must be compromised to recreate the secret, but this comes at the cost of making it more likely that the secret will be lost as *n*-*t* shrinks (the number of shares that can be safely lost). Decreasing *t* causes the opposite effect. Less shares must be compromised, but more can be lost. The advantage here is that these parameters can be adjusted, whereas without secret sharing *t* is always set to one (it's as if the key is split into *n* parts, where only one of those parts is needed to recreate the key).

The effect of adjusting *t* and *n* can also be understood probabilistically. If there are *n* shares, *t* of which must be compromised to compromise the secret, then the chance of having the secret compromised is:

$$P(compromising\; secret) = \sum_{i=t}^{n}\binom{n}{i}p^i(1-p)^{n-i}$$

Where *p* is the probability a single system will be compromised. ^[This is, of course, a summation over the binomial formula.]
 ^[This formula also assumes independent events, which probably isn't true. Having one system compromised increases the chance another system will be compromised (maybe because they run similar software).] On the other hand, the probability that the secret will be lost to a system failure is:

$$P(losing\; secret) = \sum_{i=(n-t)+1}^{n}\binom{n}{i}f^i(1-f)^{n-i}$$

Where *f* is the probability that a single system will fail. From these two formulas, it's possible to see that if your backup systems are insecure, it's best to split the secret into many shares, and then set the number of needed shares high. Even if the probability of a system being compromised is 50%, requiring 80 shares out of 100 makes the probability of compromise 5E-8%. The other side of this coin is that only 20 systems can fail, and if there's a 50% chance a given backup system will fail, then the probability of losing the secret is around 99% (21 or more systems failing).

As a side note, one fascinating aspect of this is it allows for *intrusion-tolerant systems*. Whereas large data centers have long since embraced the concept of fault-tolerance, where a system is designed to remain robust in the face of some percentage of failures, intrusion tolerant systems remain secure in the face of some percentage of intrusions. This is illustrated by the example above where the secret has a high chance of remaining secure, despite a 50% chance of a given share being compromised.

## Implementation and Practice
So what does a secret sharing backup system look like in practice? As an example, I will demonstrate how one might use this technique to backup his Bitcoin wallet. The process is simple and only consists of a handful of steps. First, encrypt the wallet with a symmetric cipher. Below, I use AES-256 in CBC mode:

``` bash
> openssl enc -aes-256-cbc -k "super_secret_password" -in wallet.dat -out wallet.dat.enc
```

The secret must then be split. There's an implementation of Shamir's secret sharing scheme called [ssss](http://point-at-infinity.org/ssss/), which can be installed with [homebrew](http://mxcl.github.com/homebrew/) on OS X.

``` bash
> ssss-split -t 3 -n 10 
Generating shares using a (3,10) scheme with dynamic security level.
Enter the secret, at most 128 ASCII characters: super_secret_password
Using a 192 bit security level.
01-58a015fc212e63ccd711d41018d0faf244de6f3fe79334fb
02-3e1aa5f58578765a79c417e0ecc18e8a949156a94af9417a
03-e200a398e04429bad1ee9b76795b552e9eb618e5f17d3028
04-fba995a0ea8d7e1d286c9f6764a51cbcc2b263caf650d712
05-27b393cd8fb121fd804613f1f13fc718c8952d864dd4a652
06-410923c42be7346b2e93d001052eb36018da1410e0bed3f7
07-9d1325a94edb6b8b86b95c9790b468c412fd5a5c5b3aa2b1
08-53d6b412a803e33bbb31b3f1f575d3cfb401103616f60d55
09-8fccb27fcd3fbcdb131b3f6760ef086bbe265e7aad727c49
10-e97602766969a94dbdcefc9794fe7c136e6967ec00180920
```

This splits "my_super_secret_password" into ten shares, three of which are needed to recreate it.

Finally, the shares can be distributed to different backup systems. For example, one share I might email to myself. Another I might ask my parents to store somewhere safe. Another I can leave in my Dropbox. They can even be stored places that aren't considered especially secure, or given to people that aren't especially trustworthy, as long as the number of untrustworthy people is less than (preferably much less than) *t*. The encrypted wallet file can even be distributed along with the key, without there being any danger that compromising that single share-data pair would lead to a breach. In other words, I can store both my encrypted wallet and a share of the secret to Dropbox, and not worry that some rogue employee with gain access to my funds.

Finally, recreating the secret is simple:

``` bash
> ssss-combine -t 3
Enter 3 shares separated by newlines:
Share [1/3]: 06-410923c42be7346b2e93d001052eb36018da1410e0bed3f7
Share [2/3]: 10-e97602766969a94dbdcefc9794fe7c136e6967ec00180920
Share [3/3]: 01-58a015fc212e63ccd711d41018d0faf244de6f3fe79334fb
Resulting secret: my_super_secret_password
```

A script for automating this process can be found in the appendix below. It uses my [xkpa password generator](https://github.com/beala/xkcd-password) to generate an encryption key. The key is then used to encrypt the specified file, and the secret is split using ssss.

## Adoption
By now, I think it's apparent that this is a powerful technique for backing up data, but what surprises me is how rarely it's used. Neither OpenSSL nor GPG implement secret sharing, which is either a cause or a symptom of the current situation. Time Machine should have an option for splitting the encryption key, and it could even be automated such that iCloud stores one of the shares. OS X's hard drive encryption would also benefit from this. When you encrypt a hard drive, it generates a recovery password, but it doesn't provide an option to split the password.

Additionally, backing up data is only one of many use cases for secret sharing. It can also be used for storing data. Systems that store sensitive data could split the data between multiple systems. For example, a bank could split your SSN between different databases on different systems, and only recreate the SSN by querying some subset of them. More than *t* must be hacked for the SSNs to be compromised. Of course, the system which recreates the SSN is a central point of failure, but extra precautions could be taken to secure it. This would be an example of an intrusion-tolerant system. In any case, I encourage developers to take a look at this technique and think of novel uses for it. I find it fascinating.

## Appendix

Gist: [https://gist.github.com/beala/5024908](https://gist.github.com/beala/5024908)

``` bash
#!/bin/bash
# Uses my xkpa password generator: https://github.com/beala/xkcd-password
# The password generation method can be modified below.

SECRETGEN="xkpa -n 10"

usage() {
    cat << EOF
Encrypts a file and splits an autogenerated key.
Shares of the key are output to n text files in
the current directory.

OPTIONS:
    -f      Plaintext input file.
    -o      Ciphertext output file.
    -t      Number of shares needed to recreate the secret.
    -n      Number of shares to generate.
    -h      Output this message.
EOF
}

while getopts "hf:o:t:n:" OPTION; do
    case "$OPTION" in
        h)
            usage
            exit 1
            ;;
        f)
            INFILE="$OPTARG"
            ;;
        o)
            OUTFILE="$OPTARG"
            ;;
        t)
            THRESHOLD="$OPTARG"
            ;;
        n)
            SHARESCOUNT="$OPTARG"
            ;;
    esac
done

DIE=false
if [[ -z "$INFILE" ]]; then
    echo "Error: Missing input file."
    DIE=true
fi
if [[ -z "$OUTFILE" ]]; then
    echo "Error: Missing output file."
    DIE=true
fi
if [[ -z "$THRESHOLD" ]]; then
    echo "Error: Missing shares threshold."
    DIE=true
fi
if [[ -z "$SHARESCOUNT" ]]; then
    echo "Error: Missing shares count."
    DIE=true
fi
if [[ $DIE == true ]]; then
    echo
    usage
    exit 1
fi

# Generate the secret.
SECRET="$($SECRETGEN)"

# Encrypt INFILE with secret. AES-256 CBC
openssl enc -aes-256-cbc -k "$SECRET" -in "$INFILE" -out "$OUTFILE"
if [[ $? != 0 ]]; then
    echo "Error: Encryption failed."
    exit $?
fi

# Split the secret into shares.
shares="$(ssss-split -t "$THRESHOLD" -n "$SHARESCOUNT" -q <<< "$SECRET")"
if [[ $? != 0 ]]; then
    echo "Error: Secret splitting failed."
    exit $?
fi

# Write each share to a different file.
i=0
for share in $shares; do
    echo "$share" > "$(basename "$INFILE")-share-$i"
    i=$((i+1))
done
```
