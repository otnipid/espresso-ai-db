# Project Vision - Espresso ML

## Overview
This repository contains the database database for the Espresso ML project. It is a collection of Kubernetes manifests, Helm charts, and database schemas that provide the foundation for the project.

This repo focuses on the database database and does not contain any application code.

## Database Schema
The database schema is defined in the `charts/postgresql/schema/schema.sql` file. It contains the schema definition for the tables, indexes, and other database objects.

## Project Architecture
The project is composed of the following components:
- Frontend application (located in the `../frontend` directory): Built with Next.js and TypeScript
- Database database (this repository): PostgreSQL database with Kubernetes deployment
- API backend (located in the `../backend` directory): Built with Node.js and TypeScript

# Goals
- Provide a scalable and reliable database database for the Espresso ML project
- Enable easy deployment and management of the database using Kubernetes and Helm
- Support the frontend and backend applications with a robust and performant database
- Unified database management across all environments
