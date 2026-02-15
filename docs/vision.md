# Project Vision - Espresso ML

## Overview
This repository contains the frontend application for the Espresso ML project. It is a collection of React components and pages that provide the user interface for the project.

This repo focuses on the frontend application and does not contain any database code.

Target Users: Professional and at-home baristas.

Core Value: Meticulous data collection, analysis, and creating the perfect espresso shot according to the users' preferences.

## Project Architecture
The project is composed of the following components:
- Frontend application (located in the `../frontend` directory): Built with Next.js and TypeScript
- Backend application (located in the `../backend` directory): Built with Node.js and TypeScript
- Database (located in the `../infrastructure` directory): Built with PostgreSQL

# Goals
- Provide a scalable and reliable frontend application for the Espresso ML project
- Enable easy deployment and management of the frontend application using Kubernetes and Helm
- Maintain consistentcy with database schema defined in `../infrastructure/charts/postgresql/schema/schema.sql` and API routes defined in `../backend/src/routes`