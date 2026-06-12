# Issue 011 - ECR ImageReferencedByManifestList

## Symptoms

Command:

```bash
aws ecr batch-delete-image \
--repository-name auth-service \
--image-ids imageDigest=DIGEST
```

Error:

```text
ImageReferencedByManifestList
```

## Root Cause

The image digest is referenced by a manifest list and cannot be deleted independently.

Example:

```text
auth-service:v1
```

references multiple underlying image digests.

## Diagnosis

Verify images:

```bash
aws ecr list-images \
--repository-name auth-service
```

Verify image details:

```bash
aws ecr describe-images \
--repository-name auth-service
```

## Resolution

Do not delete referenced digests individually.

Delete the tagged image first if complete removal is required.

## Lesson Learned

Modern container images consist of manifests and layers.

Not every digest shown in ECR is an independent image that should be deleted.
